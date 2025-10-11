import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/environment_provider.dart';

class ServerStatusIndicator extends StatelessWidget {
  const ServerStatusIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<EnvironmentProvider>(
      builder: (context, envProvider, child) {
        final config = envProvider.currentConfig;
        final isCloud = envProvider.isCloud;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isCloud 
                ? Colors.green.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCloud ? Colors.green : Colors.blue,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isCloud ? Colors.green : Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                config.icon,
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 4),
              Text(
                isCloud ? 'CLOUD' : 'LOCAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isCloud ? Colors.green : Colors.blue,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}