import 'package:flutter/material.dart';

class ShopStatusToggle extends StatelessWidget {
  final bool isOpen;
  final VoidCallback onTap;

  const ShopStatusToggle({
    super.key,
    required this.isOpen,
    required this.onTap,
  });

  static const Color primary = Color(0xFF16B8B0);
  static const Color primaryDark = Color(0xFF087F82);
  static const Color textDark = Color(0xFF173042);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 7,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isOpen
                ? primary.withOpacity(0.35)
                : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: isOpen
                    ? const LinearGradient(
                        colors: [primary, primaryDark],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isOpen ? null : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: child,
                  );
                },
                child: Icon(
                  isOpen
                      ? Icons.storefront_rounded
                      : Icons.store_rounded,
                  key: ValueKey<bool>(isOpen),
                  color: isOpen ? Colors.white : Colors.grey.shade600,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                isOpen ? 'OPEN' : 'CLOSED',
                key: ValueKey<String>(
                  isOpen ? 'open' : 'closed',
                ),
                style: TextStyle(
                  color: isOpen ? primaryDark : textDark,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.7,
                ),
              ),
            ),
            const SizedBox(width: 5),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 16,
              color: isOpen ? primaryDark : Colors.grey.shade600,
            ),
          ],
        ),
      ),
    );
  }
}