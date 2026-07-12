import 'package:draggable_home/draggable_home.dart';
import 'package:flutter/material.dart';
import 'package:link_chest/widgets/templates/vault_template.dart';

class VaultPage extends StatelessWidget {
  const VaultPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableHome(
      appBarColor: Colors.redAccent,
      title: Text("Vault"),
      headerWidget: Container(
        color: Colors.redAccent,
        child: Center(child: Text("Vault")),
      ),
      fullyStretchable: true,
      body: [SizedBox(), SizedBox(child: VaultTemplate())],
    );
  }
}
