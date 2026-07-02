import 'package:flutter/material.dart';
import 'package:link_chest/widgets/templates/vault_template.dart';

class VaultPage extends StatelessWidget {
  const VaultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vault"),
      ),
      body: VaultTemplate()
    );
  }
}