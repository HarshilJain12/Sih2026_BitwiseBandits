import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/opd_appointment.dart';

/// Service responsible for rendering and printing OPD / Appointment Slips.
///
/// Features:
/// - Clean, high-contrast thermal/receipt slip layout.
/// - Hospital header & OPD metadata.
/// - Department / Category display (no individual doctor name required).
/// - Registered patients: Encodes and prints the patient's existing QR at the bottom.
/// - Walk-in patients: Absolutely NO QR code printed.
/// - Safe error handling: Printing failures return false without crashing.
class OpdSlipPrintService {
  const OpdSlipPrintService();

  /// Generates the raw PDF bytes for an OPD appointment slip.
  Future<Uint8List> generateSlipPdf(
    OpdAppointment appointment, {
    String hospitalName = 'Kondhwa PHC Health Center',
  }) async {
    final doc = pw.Document();

    final dateStr = DateFormat('dd MMM yyyy').format(appointment.appointmentDate);
    final timeStr = appointment.appointmentTime.isNotEmpty
        ? appointment.appointmentTime
        : DateFormat('hh:mm a').format(appointment.appointmentDate);

    // QR payload for registered patients:
    // If qrPayload is given, use it; otherwise fallback to patientId
    final qrData = appointment.qrPayload ?? appointment.patientId ?? '';

    doc.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(
          80 * PdfPageFormat.mm,
          double.infinity,
          marginAll: 6 * PdfPageFormat.mm,
        ),
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.black, width: 1),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                // ── Hospital Header ──────────────────────────────
                pw.Text(
                  hospitalName.toUpperCase(),
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'OUTPATIENT DEPARTMENT (OPD) SLIP',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey800,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 1, color: PdfColors.black),
                pw.SizedBox(height: 4),

                // ── Slip Metadata ────────────────────────────────
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Time: $timeStr', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Slip ID: ${appointment.appointmentId}',
                        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.Text(
                      appointment.isRegistered ? 'REGISTERED' : 'WALK-IN',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: appointment.isRegistered ? PdfColors.blue800 : PdfColors.green800,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5, color: PdfColors.grey700),
                pw.SizedBox(height: 4),

                // ── Patient Info ─────────────────────────────────
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.SizedBox(
                            width: 65,
                            child: pw.Text('Patient Name:',
                                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              appointment.patientName,
                              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 3),
                      if (appointment.patientAge != null) ...[
                        pw.Row(
                          children: [
                            pw.SizedBox(
                              width: 65,
                              child: pw.Text('Age:',
                                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                            ),
                            pw.Text('${appointment.patientAge} Years',
                                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.SizedBox(height: 3),
                      ],
                      if (appointment.patientGender != null &&
                          appointment.patientGender!.isNotEmpty) ...[
                        pw.Row(
                          children: [
                            pw.SizedBox(
                              width: 65,
                              child: pw.Text('Gender:',
                                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                            ),
                            pw.Text(appointment.patientGender!,
                                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.SizedBox(height: 3),
                      ],
                      if (appointment.patientId != null &&
                          appointment.patientId!.isNotEmpty) ...[
                        pw.Row(
                          children: [
                            pw.SizedBox(
                              width: 65,
                              child: pw.Text('Patient ID:',
                                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                            ),
                            pw.Text(appointment.patientId!,
                                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                          ],
                        ),
                        pw.SizedBox(height: 3),
                      ],
                      pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.SizedBox(
                            width: 65,
                            child: pw.Text('Department:',
                                style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                          ),
                          pw.Expanded(
                            child: pw.Text(
                              appointment.doctorCategory.toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 6),
                pw.Divider(thickness: 1, color: PdfColors.black),
                pw.SizedBox(height: 6),

                // ── QR Code Section ──────────────────────────────
                if (appointment.isRegistered && qrData.isNotEmpty) ...[
                  pw.Text(
                    'PATIENT IDENTIFICATION QR',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.grey800,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Container(
                    width: 110,
                    height: 110,
                    padding: const pw.EdgeInsets.all(4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: PdfColors.black, width: 1),
                      color: PdfColors.white,
                    ),
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: qrData,
                      width: 100,
                      height: 100,
                      color: PdfColors.black,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    appointment.patientId ?? qrData,
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Scan for instant doctor record access',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700),
                  ),
                ] else ...[
                  // Walk-in patient: NO QR CODE!
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      '• Walk-in OPD Consultation Slip •\nPlease proceed to the consultation room.',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                    ),
                  ),
                ],

                pw.SizedBox(height: 6),
                pw.Divider(thickness: 0.5, color: PdfColors.grey600),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Arogya Seva Rural Healthcare • SIH 2026',
                  style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey600),
                ),
              ],
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  /// Prints the OPD appointment slip via the system print dialog.
  /// Returns `true` if print was successfully submitted to the printer, `false` on failure.
  Future<bool> printOpdSlip(
    OpdAppointment appointment, {
    String hospitalName = 'Kondhwa PHC Health Center',
  }) async {
    try {
      final pdfBytes = await generateSlipPdf(appointment, hospitalName: hospitalName);
      final result = await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'OPD_Slip_${appointment.appointmentId}',
      );
      return result;
    } catch (e) {
      debugPrint('[OpdSlipPrintService] Print error: $e');
      return false;
    }
  }
}
