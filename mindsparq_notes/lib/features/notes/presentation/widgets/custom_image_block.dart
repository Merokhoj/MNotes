import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';

/// Keys used in image node attributes
class CustomImageKeys {
  static const String flipH = 'flipH';
  static const String flipV = 'flipV';
  static const String rotation = 'rotation';
  static const String cropRect = 'cropRect';
}

/// Custom Image Block Component Builder for AppFlowyEditor
class CustomImageBlockComponentBuilder extends BlockComponentBuilder {
  final EditorState? editorState;

  CustomImageBlockComponentBuilder({
    this.editorState,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  BlockComponentWidget build(BlockComponentContext blockComponentContext) {
    final node = blockComponentContext.node;
    return CustomImageBlockWidget(
      key: node.key,
      node: node,
      editorState: editorState,
      configuration: configuration,
    );
  }

  @override
  bool validate(Node node) =>
      node.type == ImageBlockKeys.type && node.delta == null && node.children.isEmpty;
}

class CustomImageBlockWidget extends BlockComponentStatefulWidget {
  final EditorState? editorState;

  const CustomImageBlockWidget({
    super.key,
    required super.node,
    this.editorState,
    super.configuration = const BlockComponentConfiguration(),
  });

  @override
  State<CustomImageBlockWidget> createState() => _CustomImageBlockWidgetState();
}

class _CustomImageBlockWidgetState extends State<CustomImageBlockWidget>
    with SelectableMixin, BlockComponentConfigurable {
  @override
  BlockComponentConfiguration get configuration => widget.configuration;

  @override
  Node get node => widget.node;

  final _imageKey = GlobalKey();
  bool _isHovered = false;
  bool _isSelected = false;

  EditorState? get editorState => widget.editorState;

  @override
  Position start() => Position(path: widget.node.path, offset: 0);

  @override
  Position end() => Position(path: widget.node.path, offset: 1);

  @override
  Position getPositionInOffset(Offset start) => end();

  @override
  bool get shouldCursorBlink => false;

  @override
  CursorStyle get cursorStyle => CursorStyle.cover;

  @override
  Rect getBlockRect({bool shiftWithBaseOffset = false}) {
    final imageBox = _imageKey.currentContext?.findRenderObject();
    if (imageBox is RenderBox) {
      return Offset.zero & imageBox.size;
    }
    return Rect.zero;
  }

  @override
  Rect? getCursorRectInPosition(
    Position position, {
    bool shiftWithBaseOffset = false,
  }) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return null;
    final size = box.size;
    return Rect.fromLTWH(-size.width / 2.0, 0, size.width, size.height);
  }

  @override
  List<Rect> getRectsInSelection(
    Selection selection, {
    bool shiftWithBaseOffset = false,
  }) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return [];
    return [Offset.zero & box.size];
  }

  @override
  Selection getSelectionInRange(Offset start, Offset end) => Selection.single(
        path: widget.node.path,
        startOffset: 0,
        endOffset: 1,
      );

  @override
  Offset localToGlobal(
    Offset offset, {
    bool shiftWithBaseOffset = false,
  }) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null) {
      return box.localToGlobal(offset);
    }
    return offset;
  }

  void _updateAttributes(Map<String, dynamic> updates) {
    if (editorState == null) return;
    final transaction = editorState!.transaction
      ..updateNode(node, updates);
    editorState!.apply(transaction);
  }

  void _deleteImage() {
    if (editorState == null) return;
    final transaction = editorState!.transaction..deleteNode(node);
    editorState!.apply(transaction);
  }

  void _handleCrop(BuildContext context, String imagePath) async {
    final messenger = ScaffoldMessenger.of(context);
    final resultPath = await showDialog<String>(
      context: context,
      builder: (ctx) => ImageCropDialog(imagePath: imagePath),
    );

    if (resultPath != null && mounted) {
      _updateAttributes({
        ImageBlockKeys.url: resultPath,
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Image cropped successfully!'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final attributes = node.attributes;
    final url = attributes[ImageBlockKeys.url] as String? ?? '';
    final alignStr = attributes[ImageBlockKeys.align] as String? ?? 'center';
    final widthAttr = attributes[ImageBlockKeys.width];
    final double? customWidth = widthAttr is num ? widthAttr.toDouble() : null;
    final bool flipH = attributes[CustomImageKeys.flipH] == true;
    final bool flipV = attributes[CustomImageKeys.flipV] == true;
    final int rotation = (attributes[CustomImageKeys.rotation] as num?)?.toInt() ?? 0;

    Alignment alignment;
    switch (alignStr) {
      case 'left':
        alignment = Alignment.centerLeft;
        break;
      case 'right':
        alignment = Alignment.centerRight;
        break;
      case 'center':
      default:
        alignment = Alignment.center;
        break;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxAvailableWidth = constraints.maxWidth;
        final targetWidth = customWidth != null
            ? customWidth.clamp(120.0, maxAvailableWidth)
            : maxAvailableWidth * 0.75;

        // Transformation matrix for Flip and Rotation
        final matrix = Matrix4.identity()
          ..rotateZ(rotation * math.pi / 180.0)
          ..scale(flipH ? -1.0 : 1.0, flipV ? -1.0 : 1.0, 1.0);

        Widget imageWidget;
        if (url.startsWith('http://') || url.startsWith('https://')) {
          imageWidget = Image.network(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildPlaceholder(colors, 'Failed to load network image'),
          );
        } else if (url.startsWith('assets/')) {
          imageWidget = Image.asset(
            url,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildPlaceholder(colors, 'Asset not found'),
          );
        } else {
          final file = File(url);
          if (file.existsSync()) {
            imageWidget = Image.file(
              file,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => _buildPlaceholder(colors, 'Image file unreadable'),
            );
          } else {
            imageWidget = _buildPlaceholder(colors, 'Local image not found: $url');
          }
        }

        return MouseRegion(
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            alignment: alignment,
            child: Column(
              crossAxisAlignment: alignStr == 'left'
                  ? CrossAxisAlignment.start
                  : alignStr == 'right'
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.center,
              children: [
                // Floating Action Toolbar above or over the image
                AnimatedOpacity(
                  opacity: (_isHovered || _isSelected) ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.surface.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(color: colors.border.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Size presets
                          _sizePresetButton('25%', () => _updateAttributes({ImageBlockKeys.width: maxAvailableWidth * 0.25}), targetWidth == maxAvailableWidth * 0.25, colors),
                          _sizePresetButton('50%', () => _updateAttributes({ImageBlockKeys.width: maxAvailableWidth * 0.50}), targetWidth == maxAvailableWidth * 0.50, colors),
                          _sizePresetButton('75%', () => _updateAttributes({ImageBlockKeys.width: maxAvailableWidth * 0.75}), targetWidth == maxAvailableWidth * 0.75, colors),
                          _sizePresetButton('100%', () => _updateAttributes({ImageBlockKeys.width: maxAvailableWidth}), targetWidth == maxAvailableWidth, colors),

                          const SizedBox(width: 4),
                          Container(height: 16, width: 1, color: colors.border.withOpacity(0.4)),
                          const SizedBox(width: 4),

                          // Alignment buttons
                          _iconAction(
                            icon: PhosphorIcons.textAlignLeft(PhosphorIconsStyle.bold),
                            tooltip: 'Align Left',
                            isActive: alignStr == 'left',
                            onTap: () => _updateAttributes({ImageBlockKeys.align: 'left'}),
                            colors: colors,
                          ),
                          _iconAction(
                            icon: PhosphorIcons.textAlignCenter(PhosphorIconsStyle.bold),
                            tooltip: 'Align Center',
                            isActive: alignStr == 'center',
                            onTap: () => _updateAttributes({ImageBlockKeys.align: 'center'}),
                            colors: colors,
                          ),
                          _iconAction(
                            icon: PhosphorIcons.textAlignRight(PhosphorIconsStyle.bold),
                            tooltip: 'Align Right',
                            isActive: alignStr == 'right',
                            onTap: () => _updateAttributes({ImageBlockKeys.align: 'right'}),
                            colors: colors,
                          ),

                          const SizedBox(width: 4),
                          Container(height: 16, width: 1, color: colors.border.withOpacity(0.4)),
                          const SizedBox(width: 4),

                          // Flip & Rotate
                          _iconAction(
                            icon: PhosphorIcons.arrowsHorizontal(PhosphorIconsStyle.bold),
                            tooltip: 'Flip Horizontal',
                            isActive: flipH,
                            onTap: () => _updateAttributes({CustomImageKeys.flipH: !flipH}),
                            colors: colors,
                          ),
                          _iconAction(
                            icon: PhosphorIcons.arrowsVertical(PhosphorIconsStyle.bold),
                            tooltip: 'Flip Vertical',
                            isActive: flipV,
                            onTap: () => _updateAttributes({CustomImageKeys.flipV: !flipV}),
                            colors: colors,
                          ),
                          _iconAction(
                            icon: PhosphorIcons.arrowClockwise(PhosphorIconsStyle.bold),
                            tooltip: 'Rotate 90°',
                            onTap: () => _updateAttributes({
                              CustomImageKeys.rotation: (rotation + 90) % 360,
                            }),
                            colors: colors,
                          ),

                          // Crop tool
                          if (File(url).existsSync()) ...[
                            const SizedBox(width: 4),
                            Container(height: 16, width: 1, color: colors.border.withOpacity(0.4)),
                            const SizedBox(width: 4),
                            _iconAction(
                              icon: PhosphorIcons.crop(PhosphorIconsStyle.bold),
                              tooltip: 'Crop Image',
                              onTap: () => _handleCrop(context, url),
                              colors: colors,
                            ),
                          ],

                          const SizedBox(width: 4),
                          Container(height: 16, width: 1, color: colors.border.withOpacity(0.4)),
                          const SizedBox(width: 4),

                          // Delete
                          _iconAction(
                            icon: PhosphorIcons.trash(PhosphorIconsStyle.bold),
                            tooltip: 'Remove Image',
                            isDestructive: true,
                            onTap: _deleteImage,
                            colors: colors,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Resizable & Transformable Image Container
                GestureDetector(
                  onTap: () => setState(() => _isSelected = !_isSelected),
                  child: Container(
                    key: _imageKey,
                    width: targetWidth,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      border: Border.all(
                        color: _isSelected
                            ? colors.primary
                            : (_isHovered
                                ? colors.border.withOpacity(0.7)
                                : Colors.transparent),
                        width: 1.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                      child: Transform(
                        alignment: Alignment.center,
                        transform: matrix,
                        child: imageWidget,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(dynamic colors, String message) {
    return Container(
      height: 160,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface2.withOpacity(0.4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: colors.border.withOpacity(0.4)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.broken_image_rounded, size: 36, color: colors.textTertiary),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 12, color: colors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sizePresetButton(String label, VoidCallback onTap, bool isSelected, dynamic colors) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? colors.primary : colors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _iconAction({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required dynamic colors,
    bool isActive = false,
    bool isDestructive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: isActive ? colors.primary.withOpacity(0.16) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            icon,
            size: 15,
            color: isDestructive
                ? AppColors.error
                : (isActive ? colors.primary : colors.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// Interactive Pure Flutter Image Cropper Dialog
class ImageCropDialog extends StatefulWidget {
  final String imagePath;

  const ImageCropDialog({super.key, required this.imagePath});

  @override
  State<ImageCropDialog> createState() => _ImageCropDialogState();
}

class _ImageCropDialogState extends State<ImageCropDialog> {
  ui.Image? _decodedImage;
  bool _isLoading = true;
  String _aspectRatioMode = 'Free'; // Free, 1:1, 4:3, 16:9

  // Normalized crop region (0.0 to 1.0)
  Rect _cropRect = const Rect.fromLTWH(0.1, 0.1, 0.8, 0.8);

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    try {
      final file = File(widget.imagePath);
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() {
          _decodedImage = frame.image;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applyAspectRatio(String mode) {
    setState(() {
      _aspectRatioMode = mode;
      if (_decodedImage == null) return;

      final imgW = _decodedImage!.width.toDouble();
      final imgH = _decodedImage!.height.toDouble();

      double targetRatio = imgW / imgH;
      if (mode == '1:1') targetRatio = 1.0;
      if (mode == '4:3') targetRatio = 4.0 / 3.0;
      if (mode == '16:9') targetRatio = 16.0 / 9.0;

      if (mode == 'Free') {
        _cropRect = const Rect.fromLTWH(0.05, 0.05, 0.9, 0.9);
      } else {
        // Center-crop with target ratio
        final currentImageRatio = imgW / imgH;
        if (targetRatio > currentImageRatio) {
          // Wider than image
          final h = (1.0 / targetRatio) * currentImageRatio;
          _cropRect = Rect.fromLTWH(0.05, (1.0 - h) / 2, 0.9, h * 0.9);
        } else {
          // Taller or equal
          final w = targetRatio / currentImageRatio;
          _cropRect = Rect.fromLTWH((1.0 - w) / 2, 0.05, w * 0.9, 0.9);
        }
      }
    });
  }

  Future<void> _saveCroppedImage() async {
    if (_decodedImage == null) return;

    try {
      final imgW = _decodedImage!.width.toDouble();
      final imgH = _decodedImage!.height.toDouble();

      final srcRect = Rect.fromLTWH(
        _cropRect.left * imgW,
        _cropRect.top * imgH,
        _cropRect.width * imgW,
        _cropRect.height * imgH,
      );

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);

      final dstRect = Rect.fromLTWH(0, 0, srcRect.width, srcRect.height);
      canvas.drawImageRect(_decodedImage!, srcRect, dstRect, Paint());

      final picture = recorder.endRecording();
      final croppedUiImage = await picture.toImage(
        srcRect.width.round(),
        srcRect.height.round(),
      );

      final byteData =
          await croppedUiImage.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final dir = await getApplicationDocumentsDirectory();
      final targetDir = Directory(p.join(dir.path, 'mindsparq_notes', 'cropped_images'));
      if (!targetDir.existsSync()) {
        targetDir.createSync(recursive: true);
      }

      final fileName = 'crop_${const Uuid().v4()}.png';
      final savedFile = File(p.join(targetDir.path, fileName));
      await savedFile.writeAsBytes(byteData.buffer.asUint8List());

      if (mounted) {
        Navigator.of(context).pop(savedFile.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cropping image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: colors.border.withOpacity(0.4)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 580),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Icon(PhosphorIcons.crop(PhosphorIconsStyle.bold),
                      color: colors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Crop Image',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Aspect ratio options
              Row(
                children: [
                  const Text('Aspect Ratio: ',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 8),
                  for (final mode in ['Free', '1:1', '4:3', '16:9']) ...[
                    InkWell(
                      onTap: () => _applyAspectRatio(mode),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: _aspectRatioMode == mode
                              ? colors.primary.withOpacity(0.16)
                              : colors.surface2.withOpacity(0.5),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusSm),
                          border: Border.all(
                            color: _aspectRatioMode == mode
                                ? colors.primary
                                : colors.border.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          mode,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: _aspectRatioMode == mode
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: _aspectRatioMode == mode
                                ? colors.primary
                                : colors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14),

              // Preview & Crop Area
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(color: colors.border.withOpacity(0.3)),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _decodedImage == null
                          ? Center(
                              child: Text('Could not load image',
                                  style: TextStyle(color: colors.textSecondary)))
                          : LayoutBuilder(
                              builder: (context, box) {
                                return Stack(
                                  children: [
                                    Center(
                                      child: RawImage(
                                        image: _decodedImage,
                                        fit: BoxFit.contain,
                                        width: box.maxWidth,
                                        height: box.maxHeight,
                                      ),
                                    ),
                                    // Visual Crop Overlay Indicator
                                    Positioned(
                                      left: box.maxWidth * _cropRect.left,
                                      top: box.maxHeight * _cropRect.top,
                                      width: box.maxWidth * _cropRect.width,
                                      height: box.maxHeight * _cropRect.height,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: colors.primary, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: colors.primary.withOpacity(0.15),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                ),
              ),

              const SizedBox(height: 16),

              // Bottom Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _decodedImage != null ? _saveCroppedImage : null,
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Apply Crop'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
