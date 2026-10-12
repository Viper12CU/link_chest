import 'package:flutter/material.dart';

class ProfileHeader extends StatelessWidget {
  final String username;
  final String email;
  const ProfileHeader({
    super.key,
    required this.username,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      spacing: 12,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar de cadena de enlaces (Elemento signature)
        Row(
          spacing: 12.0,
          children: [
            LinkChainAvatar(letter: username[0]),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Text(
                  username,
                  style: textTheme.headlineSmall!.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Row(
                  spacing: 8.0,
                  children: [
                    Icon(Icons.email_outlined, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    Text(email, style: textTheme.labelLarge!.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),),
                  ],
                ),
              ],
            ),
          ],
        ),
    
      ],
    );
  }
}

class LinkChainAvatar extends StatelessWidget {
  final String letter; // Placeholder for the first letter of the username
  const LinkChainAvatar({super.key, required this.letter});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Center(
        child: Text(
          letter,
          style: theme.textTheme.displayMedium!.copyWith(
            color: theme.colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
