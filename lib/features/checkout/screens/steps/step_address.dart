import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';

final addressMapTileLayerProvider = Provider<Widget>(
  (ref) => TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'com.opizza.app_client',
  ),
);

final addressInitialPointProvider = Provider<LatLng?>((ref) => null);

/// Étape 2 : sélection de l'adresse de livraison.
///
/// [🔒 CORRECTIF — décision d'architecture révisée, voir
/// `docs/superpowers/specs/plans/base/api-corrections-phase-d.md` §3] Aucun SDK de
/// géocodage (Google Places, Mapbox) n'est présent dans ce projet, et `POST
/// /delivery/check` exige `lat`/`lng` — il ne géocode jamais une adresse texte
/// lui-même. Option retenue pour la démo : une carte OpenStreetMap
/// (`flutter_map`) où l'utilisateur place un pin par tap ; `lat`/`lng` sont lus
/// directement depuis la position du tap, sans appel réseau de géocodage. Le
/// champ texte est purement informatif (`address`), jamais utilisé pour le
/// calcul de zone côté serveur.
class StepAddress extends ConsumerStatefulWidget {
  const StepAddress({super.key});

  @override
  ConsumerState<StepAddress> createState() => _StepAddressState();
}

class _StepAddressState extends ConsumerState<StepAddress> {
  final _addressController = TextEditingController();

  // Centre par défaut si l'utilisateur n'a pas encore placé de pin — pas de
  // géolocalisation "position actuelle" ici, hors scope de cette version
  // minimale ("cheap option pour la démo", voir corrections doc §3).
  static const _defaultCenter = LatLng(48.8566, 2.3522);

  LatLng? _selectedPoint;

  @override
  void initState() {
    super.initState();
    _selectedPoint = ref.read(addressInitialPointProvider);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _onCheckZone() {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saisissez une adresse de livraison pour continuer.'),
        ),
      );
      return;
    }

    final point = _selectedPoint;
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Placez un point sur la carte pour continuer.'),
        ),
      );
      return;
    }
    ref.read(checkoutProvider.notifier).checkDeliveryAddress(
          displayAddress: address,
          lat: point.latitude,
          lng: point.longitude,
        );
  }

  @override
  Widget build(BuildContext context) {
    final checkoutState = ref.watch(checkoutProvider);

    return Column(
      children: [
        Expanded(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: _selectedPoint ?? _defaultCenter,
              initialZoom: 13,
              onTap: (_, point) => setState(() => _selectedPoint = point),
            ),
            children: [
              ref.watch(addressMapTileLayerProvider),
              if (_selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint!,
                      width: 40,
                      height: 40,
                      child: Icon(
                        Icons.location_pin,
                        color: Theme.of(context).colorScheme.primary,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Saisissez votre adresse, puis touchez la carte pour placer le repère de livraison.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresse de livraison',
                  helperText:
                      'Le repère sert à vérifier la zone, l’adresse est transmise à la commande.',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.done,
              ),
              if (_selectedPoint != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Repère : ${_selectedPoint!.latitude.toStringAsFixed(5)}, '
                  '${_selectedPoint!.longitude.toStringAsFixed(5)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: 12),
              if (checkoutState.error != null) ...[
                Text(
                  checkoutState.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: () => ref
                      .read(checkoutProvider.notifier)
                      .selectDeliveryMode(DeliveryMode.pickup),
                  child: const Text('Passer en retrait en boutique'),
                ),
                const SizedBox(height: 8),
              ],
              ElevatedButton(
                onPressed: checkoutState.isLoading ? null : _onCheckZone,
                child: checkoutState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Vérifier la zone'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
