import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/groq_service.dart';
import '../../core/services/settings_service.dart';

// ─── Data Model ──────────────────────────────────────────────────────────────
class MindNode {
  final String name;
  final List<MindNode> children;
  bool isExpanded;
  
  MindNode({
    required this.name, 
    required this.children, 
    this.isExpanded = true
  });

  factory MindNode.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'] as List<dynamic>? ?? [];
    return MindNode(
      name: json['name']?.toString() ?? 'Node',
      children: rawChildren.map((c) => MindNode.fromJson(c as Map<String, dynamic>)).toList(),
      isExpanded: true,
    );
  }
}

class _NodePosition {
  final MindNode node;
  final Offset pos;
  final int depth;
  _NodePosition(this.node, this.pos, this.depth);
}

class _Edge {
  final Offset from;
  final Offset to;
  _Edge(this.from, this.to);
}

class _TreePainter extends CustomPainter {
  final List<_Edge> edges;
  final bool isDark;
  _TreePainter(this.edges, this.isDark);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.orange.withOpacity(isDark ? 0.6 : 0.4)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final edge in edges) {
      final path = Path()..moveTo(edge.from.dx, edge.from.dy);
      final controlX = (edge.from.dx + edge.to.dx) / 2;
      path.cubicTo(
        controlX, edge.from.dy, 
        controlX, edge.to.dy, 
        edge.to.dx, edge.to.dy
      );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_TreePainter oldDelegate) => true;
}

// ─── Mind Map Screen ─────────────────────────────────────────────────────────
class MindMapScreen extends StatefulWidget {
  final String topic;
  final Function(dynamic)? onGenerated;
  final String? initialData;
  const MindMapScreen({super.key, required this.topic, this.onGenerated, this.initialData});

  @override
  State<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreen> with AutomaticKeepAliveClientMixin {
  final GroqService _groqService = GroqService();
  final SettingsService _settings = SettingsService();
  final TransformationController _transformationController = TransformationController();
  final GlobalKey _boundaryKey = GlobalKey();
  
  MindNode? _rootNode;
  bool _isLoading = false;
  bool _isExporting = false;

  final List<_NodePosition> _nodePositions = [];
  final List<_Edge> _edges = [];

  static const double _canvasWidth = 4000;
  static const double _canvasHeight = 4000;
  static const double _horizontalSpacing = 260;
  static const double _verticalSpacing = 90;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _parseData(widget.initialData!);
    }
    _centerView();
  }

  void _parseData(String data) {
    try {
      final json = jsonDecode(data);
      _rootNode = MindNode.fromJson(json);
      _performBetterLayout();
    } catch (e) {
      debugPrint('Error parsing MindMap data: $e');
    }
  }

  void _centerView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final screenHeight = MediaQuery.of(context).size.height;
        _transformationController.value = Matrix4.identity()
          ..translate(50.0, -(2000.0 - screenHeight / 3));
      }
    });
  }

  Future<void> _fetchMindMap() async {
    setState(() => _isLoading = true);
    try {
      final raw = await _groqService.generateMindMap(widget.topic);
      String cleaned = raw.trim();
      if (cleaned.contains('```')) {
        final start = cleaned.indexOf('{');
        final end = cleaned.lastIndexOf('}');
        if (start != -1 && end != -1) cleaned = cleaned.substring(start, end + 1);
      }
      _parseData(cleaned);
      setState(() => _isLoading = false);
      if (widget.onGenerated != null) widget.onGenerated!(cleaned);
      _centerView();
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _performBetterLayout() {
    if (_rootNode == null) return;
    _nodePositions.clear();
    _edges.clear();

    Map<MindNode, double> heights = {};
    _getTreeHeight(_rootNode!, heights);
    
    _placeNodeHorizontally(_rootNode!, 200, _canvasHeight / 2, 0, heights);
  }

  double _getTreeHeight(MindNode node, Map<MindNode, double> heights) {
    if (!node.isExpanded || node.children.isEmpty) {
      heights[node] = _verticalSpacing;
      return _verticalSpacing;
    }
    double h = 0;
    for (var child in node.children) {
      h += _getTreeHeight(child, heights);
    }
    heights[node] = h;
    return h;
  }

  void _placeNodeHorizontally(MindNode node, double x, double y, int depth, Map<MindNode, double> heights) {
    _nodePositions.add(_NodePosition(node, Offset(x, y), depth));

    if (!node.isExpanded || node.children.isEmpty) return;

    double totalH = heights[node]!;
    double startY = y - totalH / 2;
    double currentY = startY;

    for (var child in node.children) {
      double childH = heights[child]!;
      double childY = currentY + childH / 2;
      _edges.add(_Edge(Offset(x + 80, y), Offset(x + _horizontalSpacing - 80, childY)));
      _placeNodeHorizontally(child, x + _horizontalSpacing, childY, depth + 1, heights);
      currentY += childH;
    }
  }

  Future<void> _exportImage() async {
    setState(() => _isExporting = true);
    try {
      await Future.delayed(const Duration(milliseconds: 200));
      final RenderRepaintBoundary? boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw Exception('Boundary not found');
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();
      final blob = html.Blob([pngBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)..setAttribute("download", "mind_map.png")..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Export failed: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) {
        final isDark = _settings.isDarkMode;
        final isArabic = _settings.locale.languageCode == 'ar';

        if (_rootNode == null && !_isLoading) return _buildGenerateState(isDark, isArabic);
        if (_isLoading) return Center(child: CircularProgressIndicator(color: Colors.orange));

        _performBetterLayout(); 

        return Stack(
          children: [
            InteractiveViewer(
              transformationController: _transformationController,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(2000),
              minScale: 0.1,
              maxScale: 2.5,
              child: RepaintBoundary(
                key: _boundaryKey,
                child: Container(
                  width: _canvasWidth,
                  height: _canvasHeight,
                  color: isDark ? AppColors.darkBackground : Colors.white,
                  child: Stack(
                    children: [
                      Positioned.fill(child: CustomPaint(painter: _TreePainter(_edges, isDark))),
                      ..._nodePositions.map((np) => _buildNode(np, isDark)),
                    ],
                  ),
                ),
              ),
            ),
            
            Positioned(
              top: 24,
              right: 24,
              child: Column(
                children: [
                  _toolbarButton(Icons.center_focus_strong_rounded, _centerView, isArabic ? 'توسيط' : 'Recenter', isDark),
                  const SizedBox(height: 12),
                  _toolbarButton(
                    Icons.download_rounded, 
                    _isExporting ? null : _exportImage, 
                    isArabic ? 'تصدير' : 'Export',
                    isDark,
                    isLoading: _isExporting
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _toolbarButton(IconData icon, VoidCallback? onTap, String tooltip, bool isDark, {bool isLoading = false}) {
    return FloatingActionButton(
      heroTag: tooltip,
      onPressed: onTap,
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      elevation: 2,
      child: isLoading 
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
        : Icon(icon, color: Colors.orange),
    );
  }

  Widget _buildNode(_NodePosition np, bool isDark) {
    final hasChildren = np.node.children.isNotEmpty;
    final isRoot = np.depth == 0;

    return Positioned(
      left: np.pos.dx - 80,
      top: np.pos.dy - 35,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: hasChildren ? () => setState(() => np.node.isExpanded = !np.node.isExpanded) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 160,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isDark 
                  ? (isRoot ? const Color(0xFF311B92).withOpacity(0.3) : (np.depth == 1 ? const Color(0xFF0D47A1).withOpacity(0.3) : const Color(0xFF004D40).withOpacity(0.3)))
                  : (isRoot ? const Color(0xFFEDE7F6) : (np.depth == 1 ? const Color(0xFFE3F2FD) : const Color(0xFFE0F2F1))),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.06), blurRadius: 10, offset: const Offset(0, 4)),
                ],
                border: Border.all(
                  color: isRoot 
                    ? Colors.orange.withOpacity(0.5) 
                    : (isDark ? Colors.white12 : Colors.black.withOpacity(0.05)), 
                  width: 1.5
                ),
              ),
              child: Text(
                np.node.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isRoot ? 14 : 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          if (hasChildren)
            Transform.translate(
              offset: const Offset(-8, 0),
              child: GestureDetector(
                onTap: () => setState(() => np.node.isExpanded = !np.node.isExpanded),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Icon(
                    np.node.isExpanded ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
                    size: 16,
                    color: Colors.orange,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGenerateState(bool isDark, bool isArabic) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.account_tree_rounded, size: 80, color: Colors.orange),
            ),
            const SizedBox(height: 32),
            Text(
              isArabic ? 'خريطة ذهنية تفاعلية' : 'Interactive Mind Map', 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)
            ),
            const SizedBox(height: 12),
            Text(
              isArabic ? 'أنشئ هيكلاً شجرياً بصرياً لموضوعك.' : 'Generate a visual tree structure of your topic.', 
              style: TextStyle(color: isDark ? AppColors.darkTextSecondary : Colors.grey)
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _fetchMindMap,
              icon: const Icon(Icons.auto_awesome, color: Colors.white),
              label: Text(
                isArabic ? 'توليد الخريطة' : 'Generate Map', 
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
