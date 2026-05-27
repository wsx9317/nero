import 'package:flutter/material.dart';

class Space extends StatefulWidget {
  final double spaceWidth;
  final double spaceHeight;
  const Space({super.key, required this.spaceWidth, required this.spaceHeight});

  @override
  State<Space> createState() => _SpaceState();
}

class _SpaceState extends State<Space> {
  @override
  Widget build(BuildContext context) {
    Widget wg1 = SizedBox(
      width: widget.spaceWidth,
      height: widget.spaceHeight,
    );
    return wg1;
  }
}
