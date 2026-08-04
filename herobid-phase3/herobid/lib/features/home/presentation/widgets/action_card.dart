import 'package:flutter/material.dart';

class ActionCard extends StatefulWidget {
  const ActionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    this.comingSoon = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool comingSoon;

  @override
  State<ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<ActionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    setState(() => _hovered = hovering);
    if (hovering) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => _onHover(true),
        onExit: (_) => _onHover(false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.05),
              border: Border.all(
                color: widget.color.withOpacity(_hovered ? 0.7 : 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(_hovered ? 0.25 : 0.1),
                  blurRadius: _hovered ? 30 : 15,
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 28),
                    ),
                    const Spacer(),
                    if (widget.comingSoon)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white24,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Phase 5',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Colors.white38,
                                    letterSpacing: 0.8,
                                  ),
                        ),
                      ),
                    if (!widget.comingSoon)
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: widget.color.withOpacity(0.7),
                        size: 16,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  widget.title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white54,
                        height: 1.5,
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
