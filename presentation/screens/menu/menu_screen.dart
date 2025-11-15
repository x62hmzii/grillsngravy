import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:grillsngravy/core/constants/colors.dart';
import 'package:grillsngravy/services/firebase_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  String _whatsappNumber = '+84968607864';
  bool _isLoadingWhatsApp = false;

  @override
  void initState() {
    super.initState();
    _loadWhatsAppNumber();
  }

  Future<void> _loadWhatsAppNumber() async {
    try {
      // Firebase se WhatsApp number load karein
      final number = await FirebaseService.getWhatsAppNumber();
      if (mounted) {
        setState(() {
          _whatsappNumber = number;
        });
      }
    } catch (e) {
      print('Error loading WhatsApp number: $e');
      if (mounted) {
        setState(() {
          _whatsappNumber = '+84968607864'; // Default number
        });
      }
    }
  }

  // ✅ PERFECT WhatsApp Launch Function
  Future<void> _launchWhatsApp() async {
    if (_whatsappNumber.isEmpty) {
      _showErrorSnackBar('WhatsApp number is not set.');
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoadingWhatsApp = true;
    });

    try {
      // WhatsApp number clean karein (spaces, dashes, brackets remove karein)
      String cleanNumber = _whatsappNumber.replaceAll(RegExp(r'[\s\-()]'), '');

      // Country code ke saath number ensure karein
      if (!cleanNumber.startsWith('+')) {
        cleanNumber = '+$cleanNumber';
      }

      // ✅ CORRECT WhatsApp URL format
      final whatsappUrl = 'https://wa.me/$cleanNumber';

      // ✅ Alternative: Direct chat URL
      final whatsappDirectUrl = 'whatsapp://send?phone=$cleanNumber&text=Hello%2C%20I%20would%20like%20to%20place%20an%20order';

      print('Trying to launch WhatsApp with number: $cleanNumber');
      print('URL: $whatsappUrl');

      bool launched = false;

      // Pehle direct WhatsApp URL try karein
      if (await canLaunchUrl(Uri.parse(whatsappDirectUrl))) {
        await launchUrl(
          Uri.parse(whatsappDirectUrl),
          mode: LaunchMode.externalApplication,
        );
        launched = true;
        print('Launched via direct WhatsApp URL');
      }
      // Phir web URL try karein
      else if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
        launched = true;
        print('Launched via web WhatsApp URL');
      }

      if (!launched) {
        _showErrorSnackBar('Cannot open WhatsApp. Please make sure WhatsApp is installed.');

        // Fallback: Play Store par le jayein agar WhatsApp installed nahi hai
        final playStoreUrl = 'https://play.google.com/store/apps/details?id=com.whatsapp';
        if (await canLaunchUrl(Uri.parse(playStoreUrl))) {
          await launchUrl(Uri.parse(playStoreUrl), mode: LaunchMode.externalApplication);
        }
      }
    } catch (e) {
      print('WhatsApp launch error: $e');
      _showErrorSnackBar('Error opening WhatsApp: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingWhatsApp = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ✅ PERMISSION-FREE Download Function (FIXED)
  Future<void> _downloadAndOpenFile(String fileUrl, String fileName, String fileType) async {
    try {
      // 1. Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(width: 16),
              Text(
                'Downloading...',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
        ),
      );

      // 2. Download file
      final response = await http.get(Uri.parse(fileUrl)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Download timeout');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Download failed with status: ${response.statusCode}');
      }

      // 3. ✅ PERMISSION-FREE: Use app's temporary directory (no permissions needed)
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);

      // 4. Write file to temporary directory
      await file.writeAsBytes(response.bodyBytes);

      // 5. Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // 6. Open file using OpenFilex
      final result = await OpenFilex.open(filePath);

      if (result.type == ResultType.done) {
        _showSuccessSnackBar('File downloaded successfully!');
      } else {
        _showSuccessSnackBar('File downloaded! You can find it in your downloads.');
      }

    } on TimeoutException catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorSnackBar('Download timeout: ${e.message}');
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      print('Download failed: $e');
      _showErrorSnackBar('Download failed: ${e.toString()}');
    }
  }

  void _viewFile(String fileUrl, String title, String fileType) {
    if (fileType.toLowerCase() == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(
            fileUrl: fileUrl,
            title: title,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewerScreen(
            imageUrl: fileUrl,
            title: title,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Our Menu',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: FirebaseService.getMenuDocuments(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: AppColors.primary));
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading menu: ${snapshot.error}',
                style: GoogleFonts.poppins(),
                textAlign: TextAlign.center,
              ),
            );
          }

          final menuItems = snapshot.data ?? [];

          if (menuItems.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.menu_book,
                    size: 64,
                    color: AppColors.greyLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No menu available',
                    style: GoogleFonts.poppins(
                      color: AppColors.greyDark,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _launchWhatsApp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Contact via WhatsApp'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return _buildMenuItemCard(item);
            },
          );
        },
      ),
    );
  }

  Widget _buildMenuItemCard(Map<String, dynamic> item) {
    final title = item['title'] ?? 'Untitled';
    final fileUrl = item['fileUrl'] ?? '';
    final fileType = item['fileType'] ?? 'pdf';

    // Clean file name for download
    final cleanTitle = title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
    final fileName = '$cleanTitle.${fileType.toLowerCase()}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    fileType.toLowerCase() == 'pdf'
                        ? Icons.picture_as_pdf
                        : Icons.image,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onBackground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // View and Download Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewFile(fileUrl, title, fileType),
                    icon: const Icon(Icons.remove_red_eye, size: 18),
                    label: const Text('View'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _downloadAndOpenFile(fileUrl, fileName, fileType),
                    icon: const Icon(Icons.download, size: 18),
                    label: const Text('Download'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.info,
                      side: const BorderSide(color: AppColors.info),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // WhatsApp Order Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoadingWhatsApp ? null : _launchWhatsApp,
                icon: _isLoadingWhatsApp
                    ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.onPrimary,
                  ),
                )
                    : const Icon(Icons.chat, size: 18),
                label: _isLoadingWhatsApp
                    ? const Text('Opening...')
                    : const Text('Order on WhatsApp'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 2,
                ),
              ),
            ),

            // WhatsApp Number Display
            if (_whatsappNumber.isNotEmpty) ...[
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Contact: $_whatsappNumber',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// PDF Viewer Screen
class PdfViewerScreen extends StatelessWidget {
  final String fileUrl;
  final String title;

  const PdfViewerScreen({
    super.key,
    required this.fileUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.picture_as_pdf,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'PDF File Viewer',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                'This screen is a placeholder. To view the PDF, please use the download button and open it with an external PDF reader.',
                style: GoogleFonts.poppins(
                  color: AppColors.greyDark,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Download and open PDF directly using the same permission-free method
                _downloadAndOpenPdf(context, fileUrl, title);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Download & Open PDF'),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadAndOpenPdf(BuildContext context, String fileUrl, String title) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(width: 16),
              Text('Downloading PDF...'),
            ],
          ),
        ),
      );

      // Download file
      final response = await http.get(Uri.parse(fileUrl));

      if (response.statusCode != 200) {
        throw Exception('Download failed');
      }

      // Use temporary directory (no permissions needed)
      final tempDir = await getTemporaryDirectory();
      final fileName = '${title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_')}.pdf';
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(response.bodyBytes);

      // Close loading
      if (context.mounted) Navigator.of(context).pop();

      // Open file
      final result = await OpenFilex.open(filePath);

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF downloaded but could not open automatically'),
            backgroundColor: AppColors.info,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}

// Image Viewer Screen
class ImageViewerScreen extends StatelessWidget {
  final String imageUrl;
  final String title;

  const ImageViewerScreen({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.1,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => CircularProgressIndicator(
              color: AppColors.primary,
            ),
            errorWidget: (context, url, error) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: AppColors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load image',
                  style: GoogleFonts.poppins(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}