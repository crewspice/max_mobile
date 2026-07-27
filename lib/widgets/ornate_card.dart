import 'dart:math' as math;
import 'package:flutter/material.dart';

class OrnateCard extends StatefulWidget {
  const OrnateCard({
    super.key,
    required this.child,
    required this.color,
    this.padding = const EdgeInsets.all(6),
    this.borderThickness = 16,
    this.tileSize = 6,
    this.useExperimentalCorner = true,
    this.useExperimentalEdge = true,
  });

  final Widget child;
  final Color color;
  final EdgeInsets padding;
  final double tileSize;
  final double borderThickness;

  final bool useExperimentalCorner;
  final bool useExperimentalEdge;

  @override
  State<OrnateCard> createState() => _OrnateCardState();
}

class _OrnateCardState extends State<OrnateCard> {
  final GlobalKey _contentKey = GlobalKey();

  Size _contentSize = Size.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didUpdateWidget(covariant OrnateCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final ctx = _contentKey.currentContext;
    if (ctx == null) return;

    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;

    if (box.size != _contentSize) {
      setState(() {
        _contentSize = box.size;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = widget.borderThickness;

    final horizontalTiles = math.max(
      1,
      (_contentSize.width / widget.tileSize).ceil(),
    );

    final verticalTiles = math.max(
      1,
      (_contentSize.height / widget.tileSize).ceil(),
    );

    final tileWidth = _contentSize.width / horizontalTiles;
    final tileHeight = _contentSize.height / verticalTiles;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: EdgeInsets.all(border),
          child: Container(
            key: _contentKey,
            padding: widget.padding,
            child: widget.child,
          ),
        ),

        Positioned(
          left: 0,
          top: border,
          bottom: border,
          width: border,
          child: _verticalEdge(
            verticalTiles,
            tileHeight,
            0,
          ),
        ),

        Positioned(
          right: 0,
          top: border,
          bottom: border,
          width: border,
          child: _verticalEdge(
            verticalTiles,
            tileHeight,
            math.pi,
          ),
        ),

        Positioned(
          left: border,
          right: border,
          top: 0,
          height: border,
          child: _horizontalEdge(
            horizontalTiles,
            tileWidth,
            math.pi / 2,
          ),
        ),

        Positioned(
          left: border,
          right: border,
          bottom: 0,
          height: border,
          child: _horizontalEdge(
            horizontalTiles,
            tileWidth,
            -math.pi / 2,
          ),
        ),

        Positioned(
          left: 0,
          top: 0,
          child: _corner(0),
        ),

        Positioned(
          right: 0,
          top: 0,
          child: _corner(math.pi / 2),
        ),

        Positioned(
          left: 0,
          bottom: 0,
          child: _corner(-math.pi / 2),
        ),

        Positioned(
          right: 0,
          bottom: 0,
          child: _corner(math.pi),
        ),
      ],
    );
  }

  Widget _verticalEdge(
    int count,
    double tileHeight,
    double rotation,
  ) {
    return Column(
      children: List.generate(
        count,
        (_) => SizedBox(
          height: tileHeight,
          width: widget.borderThickness,
          child: _edgeTile(rotation),
        ),
      ),
    );
  }

  Widget _horizontalEdge(
    int count,
    double tileWidth,
    double rotation,
  ) {
    return Row(
      children: List.generate(
        count,
        (_) => SizedBox(
          width: tileWidth,
          height: widget.borderThickness,
          child: _edgeTile(rotation),
        ),
      ),
    );
  }

  Widget _edgeTile(double rotation) {
    if (widget.useExperimentalEdge) {
      return Transform.rotate(
        angle: rotation,
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            widget.color,
            BlendMode.srcIn,
          ),
          child: Image.asset(
            'assets/edge.png',
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return _devTile();
  }

  Widget _devTile() {
    return Container(
      margin: const EdgeInsets.all(.5),
      decoration: BoxDecoration(
        color: widget.color,
        border: Border.all(
          color: Colors.white,
          width: .5,
        ),
      ),
    );
  }

  Widget _corner(double rotation) {
    if (widget.useExperimentalCorner) {
      return Transform.rotate(
        angle: rotation,
        child: SizedBox(
          width: widget.borderThickness,
          height: widget.borderThickness,
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              widget.color,
              BlendMode.srcIn,
            ),
            child: Image.asset(
              'assets/corner.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      );
    }

    return Container(
      width: widget.borderThickness,
      height: widget.borderThickness,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: widget.color,
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          width: widget.borderThickness * .45,
          height: widget.borderThickness * .45,
          color: widget.color,
        ),
      ),
    );
  }
}