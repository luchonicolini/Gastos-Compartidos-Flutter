import 'package:flutter/material.dart';

class GroupDetailBottomNav extends StatelessWidget {
  const GroupDetailBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: Icons.receipt_long_rounded,
            label: 'Gastos',
            isSelected: selectedIndex == 0,
            onTap: () => onChanged(0),
          ),
          _NavItem(
            icon: Icons.people_outline_rounded,
            label: 'Personas',
            isSelected: selectedIndex == 1,
            onTap: () => onChanged(1),
          ),
          _NavItem(
            icon: Icons.swap_horiz_rounded,
            label: 'Cuentas',
            isSelected: selectedIndex == 2,
            onTap: () => onChanged(2),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 58,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? colors.secondaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? colors.primary : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Figtree',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? colors.onSurface : colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
