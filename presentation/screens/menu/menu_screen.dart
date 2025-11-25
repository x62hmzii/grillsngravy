import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:grillsngravy/core/constants/colors.dart';
import 'package:grillsngravy/services/firebase_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

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
          _whatsappNumber = '+84968607864';
        });
      }
    }
  }

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
      String cleanNumber = _whatsappNumber.replaceAll(RegExp(r'[\s\-()]'), '');

      if (!cleanNumber.startsWith('+')) {
        cleanNumber = '+$cleanNumber';
      }

      final whatsappUrl = 'https://wa.me/$cleanNumber';
      final whatsappDirectUrl = 'whatsapp://send?phone=$cleanNumber&text=Hello%2C%20I%20would%20like%20to%20place%20an%20order';

      bool launched = false;

      if (await canLaunchUrl(Uri.parse(whatsappDirectUrl))) {
        await launchUrl(
          Uri.parse(whatsappDirectUrl),
          mode: LaunchMode.externalApplication,
        );
        launched = true;
      }
      else if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(
          Uri.parse(whatsappUrl),
          mode: LaunchMode.externalApplication,
        );
        launched = true;
      }

      if (!launched) {
        _showErrorSnackBar('Cannot open WhatsApp. Please make sure WhatsApp is installed.');

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

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.photos.isGranted || await Permission.storage.isGranted) {
        return true;
      }

      Map<Permission, PermissionStatus> statuses = await [
        Permission.photos,
        Permission.storage,
      ].request();

      return statuses[Permission.photos]?.isGranted == true ||
          statuses[Permission.storage]?.isGranted == true;
    }
    return true;
  }

  Future<void> _downloadAndSaveToGallery(String fileUrl, String fileName) async {
    try {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        _showErrorSnackBar('Storage permission is required to save images');
        return;
      }

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

      final response = await http.get(Uri.parse(fileUrl)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Download timeout');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Download failed with status: ${response.statusCode}');
      }

      final result = await ImageGallerySaverPlus.saveImage(
        response.bodyBytes,
        quality: 100,
        name: fileName,
      );

      if (!mounted) return;
      Navigator.of(context).pop();

      if (result['isSuccess'] == true) {
        _showSuccessSnackBar('Image saved to gallery successfully!');
      } else {
        _showErrorSnackBar('Failed to save image to gallery');
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

  Future<void> _downloadPdfToDownloads(String fileUrl, String fileName) async {
    try {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        _showErrorSnackBar('Storage permission is required to download files');
        return;
      }

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
                'Downloading PDF...',
                style: GoogleFonts.poppins(),
              ),
            ],
          ),
        ),
      );

      final response = await http.get(Uri.parse(fileUrl)).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Download timeout');
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Download failed with status: ${response.statusCode}');
      }

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final filePath = '${directory!.path}/$fileName';
      final file = File(filePath);
      await file.writeAsBytes(response.bodyBytes);

      if (!mounted) return;
      Navigator.of(context).pop();

      _showSuccessSnackBar('PDF downloaded to Downloads folder!');

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
          'Menu',
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
    final hasMultipleImages = item['multipleImages'] ?? false;
    final imageUrls = List<String>.from(item['imageUrls'] ?? []);
    final isPdf = fileType.toLowerCase() == 'pdf' && fileUrl.isNotEmpty;
    final hasImages = hasMultipleImages && imageUrls.isNotEmpty;

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPdf ? Icons.picture_as_pdf : Icons.image,
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
                if (hasImages && imageUrls.length > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${imageUrls.length} images',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (isPdf)
              _buildPdfContent(fileUrl, title, fileName)
            else if (hasImages)
              _buildImagesContent(imageUrls, title)
            else
              _buildNoContentSection(),

            const SizedBox(height: 16),

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

  Widget _buildPdfContent(String fileUrl, String title, String fileName) {
    return Column(
      children: [
        Container(
          height: 150,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.picture_as_pdf,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                'PDF Menu',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _viewFile(fileUrl, title, 'pdf'),
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
                onPressed: () => _downloadPdfToDownloads(fileUrl, fileName),
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
      ],
    );
  }

  Widget _buildImagesContent(List<String> imageUrls, String title) {
    return Column(
      children: [
        SizedBox(
          height: imageUrls.length > 1 ? 120 : 200,
          child: ListView.builder(
            scrollDirection: imageUrls.length > 1 ? Axis.horizontal : Axis.vertical,
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ImageViewerScreen(
                        imageUrl: imageUrls[index],
                        title: imageUrls.length > 1 ? '$title - Image ${index + 1}' : title,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: imageUrls.length > 1 ? 160 : double.infinity,
                  height: imageUrls.length > 1 ? 120 : 200,
                  margin: EdgeInsets.only(
                    right: imageUrls.length > 1 && index < imageUrls.length - 1 ? 12 : 0,
                    bottom: imageUrls.length == 1 ? 0 : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.greyLight),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        CachedNetworkImage(
                          imageUrl: imageUrls[index],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          placeholder: (context, url) => Container(
                            color: AppColors.greyLight,
                            child: const Icon(Icons.image, color: AppColors.grey),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.greyLight,
                            child: const Icon(Icons.error_outline, color: AppColors.error),
                          ),
                        ),
                        if (imageUrls.length > 1)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${index + 1}',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        if (imageUrls.length > 1) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageGalleryScreen(
                          imageUrls: imageUrls,
                          title: title,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.collections, size: 18),
                  label: const Text('View All'),
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
                  onPressed: () {
                    _downloadMultipleImages(imageUrls, title);
                  },
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download '),
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
        ] else if (imageUrls.length == 1) ...[
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ImageViewerScreen(
                          imageUrl: imageUrls[0],
                          title: title,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.fullscreen, size: 18),
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
                  onPressed: () {
                    final cleanTitle = title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
                    _downloadAndSaveToGallery(imageUrls[0], '$cleanTitle.jpg');
                  },
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
        ],
      ],
    );
  }

  Widget _buildNoContentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.greyLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.grey, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'No menu content available',
              style: GoogleFonts.poppins(
                color: AppColors.grey,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadMultipleImages(List<String> imageUrls, String title) async {
    try {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        _showErrorSnackBar('Storage permission is required to save images');
        return;
      }

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Downloading ${imageUrls.length} images...',
                style: GoogleFonts.poppins(),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );

      int successCount = 0;

      for (int i = 0; i < imageUrls.length; i++) {
        try {
          final response = await http.get(Uri.parse(imageUrls[i])).timeout(
            const Duration(seconds: 30),
          );

          if (response.statusCode == 200) {
            final cleanTitle = title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
            final result = await ImageGallerySaverPlus.saveImage(
              response.bodyBytes,
              quality: 100,
              name: '${cleanTitle}_${i + 1}',
            );

            if (result['isSuccess'] == true) {
              successCount++;
            }
          }
        } catch (e) {
          print('Failed to download image ${i + 1}: $e');
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop();

      if (successCount > 0) {
        _showSuccessSnackBar('$successCount out of ${imageUrls.length} images saved to gallery!');
      } else {
        _showErrorSnackBar('Failed to download images. Please try again.');
      }

    } on TimeoutException catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorSnackBar('Download timeout: ${e.message}');
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      print('Multiple images download failed: $e');
      _showErrorSnackBar('Download failed: ${e.toString()}');
    }
  }
}

class ImageGalleryScreen extends StatelessWidget {
  final List<String> imageUrls;
  final String title;

  const ImageGalleryScreen({
    super.key,
    required this.imageUrls,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: AppColors.primary, // ← TEXT RED COLOR (aapka primary color)
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white, // ← APP BAR BACKGROUND WHITE
        foregroundColor: AppColors.primary, // ← BACK ARROW RED COLOR
        elevation: 0,
        iconTheme: IconThemeData(
          color: AppColors.primary, // ← BACK ARROW RED COLOR
        ),
      ),
      body: PageView.builder(
        itemCount: imageUrls.length,
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.1,
            maxScale: 4.0,
            child: CachedNetworkImage(
              imageUrl: imageUrls[index],
              fit: BoxFit.contain,
              placeholder: (context, url) => Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              errorWidget: (context, url, error) => Center(
                child: Column(
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
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: AppColors.surface,
        child: Text(
          'Swipe to view all ${imageUrls.length} images',
          style: GoogleFonts.poppins(
            color: AppColors.grey,
            fontSize: 14,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

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
                _downloadPdf(context, fileUrl, title);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: const Text('Download PDF'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      if (await Permission.photos.isGranted || await Permission.storage.isGranted) {
        return true;
      }

      Map<Permission, PermissionStatus> statuses = await [
        Permission.photos,
        Permission.storage,
      ].request();

      return statuses[Permission.photos]?.isGranted == true ||
          statuses[Permission.storage]?.isGranted == true;
    }
    return true;
  }

  void _downloadPdf(BuildContext context, String fileUrl, String title) async {
    try {
      final hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Storage permission is required to download files'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

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

      final response = await http.get(Uri.parse(fileUrl)).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode != 200) {
        throw Exception('Download failed');
      }

      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      final fileName = '${title.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_')}.pdf';
      final filePath = '${directory!.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(response.bodyBytes);

      if (context.mounted) Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF downloaded to Downloads folder!'),
          backgroundColor: AppColors.success,
        ),
      );

    } on TimeoutException catch (e) {
      if (context.mounted) Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download timeout: ${e.message}'),
          backgroundColor: AppColors.error,
        ),
      );
    } catch (e) {
      if (context.mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      print('Download failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

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