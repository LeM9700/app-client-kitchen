import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import 'package:app_client/core/theme/app_typography.dart';
import 'package:app_client/core/theme/kitchen_radius.dart';
import 'package:app_client/core/theme/kitchen_spacing.dart';
import 'package:app_client/core/theme/kitchen_tokens.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_embossed_button.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_surface.dart';
import 'package:app_client/core/widgets/kitchen/kitchen_text_field.dart';
import 'package:app_client/features/checkout/models/checkout_state.dart';
import 'package:app_client/features/checkout/providers/checkout_provider.dart';
import 'package:app_client/features/checkout/widgets/kitchen_delivery_status.dart';
import 'package:app_client/l10n/app_localizations.dart';

final addressMapTileLayerProvider = Provider<Widget>(
  (ref) => TileLayer(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    userAgentPackageName: 'com.opizza.app_client',
  ),
);

final addressInitialPointProvider = Provider<LatLng?>((ref) => null);

/// Etape 2 : selection de l'adresse de livraison.
///
/// `POST /delivery/check` exige lat/lng. La carte OpenStreetMap reste donc la
/// source des coordonnees, et le champ texte reste une adresse affichee.
class StepAddress extends ConsumerStatefulWidget {
  const StepAddress({super.key});

  @override
  ConsumerState<StepAddress> createState() => _StepAddressState();
}

class _StepAddressState extends ConsumerState<StepAddress> {
  final _addressController = TextEditingController();

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
    final l10n = AppLocalizations.of(context)!;
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.checkoutAddressMissingError)),
      );
      return;
    }

    final point = _selectedPoint;
    if (point == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.checkoutPinMissingError)),
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
    final l10n = AppLocalizations.of(context)!;
    final status = _deliveryStatusFor(checkoutState);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        KitchenSpacing.lg,
        KitchenSpacing.md,
        KitchenSpacing.lg,
        KitchenSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Adresse de livraison',
            style: KitchenTypography.title.copyWith(fontSize: 30),
          ),
          const SizedBox(height: KitchenSpacing.xs),
          Text(
            l10n.checkoutAddressInstructions,
            style:
                KitchenTypography.body.copyWith(color: KitchenColors.textMuted),
          ),
          const SizedBox(height: KitchenSpacing.lg),
          KitchenSurface(
            padding: const EdgeInsets.all(KitchenSpacing.xs),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(KitchenRadius.lg),
              child: SizedBox(
                height: 280,
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
                            width: 44,
                            height: 44,
                            child: const Icon(
                              Icons.location_pin,
                              color: KitchenColors.cognac,
                              size: 42,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: KitchenSpacing.md),
          KitchenTextField(
            controller: _addressController,
            label: l10n.checkoutStepAddressTitle,
            hintText: '12 rue des Oliviers, 69007 Lyon',
            prefixIcon: Icons.home_outlined,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _onCheckZone(),
          ),
          if (_selectedPoint != null) ...[
            const SizedBox(height: KitchenSpacing.xs),
            Text(
              l10n.checkoutPinCoordinates(
                _selectedPoint!.latitude.toStringAsFixed(5),
                _selectedPoint!.longitude.toStringAsFixed(5),
              ),
              style: KitchenTypography.body.copyWith(
                color: KitchenColors.textMuted,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: KitchenSpacing.md),
          KitchenDeliveryStatus(
            type: status.type,
            title: status.title,
            subtitle: status.subtitle,
          ),
          if (checkoutState.error != null) ...[
            const SizedBox(height: KitchenSpacing.sm),
            TextButton.icon(
              onPressed: () => ref
                  .read(checkoutProvider.notifier)
                  .selectDeliveryMode(DeliveryMode.pickup),
              icon: const Icon(Icons.storefront_outlined),
              label: Text(l10n.checkoutSwitchToPickup),
              style: TextButton.styleFrom(
                foregroundColor: KitchenColors.cognac,
                minimumSize: const Size(44, 44),
              ),
            ),
          ],
          const SizedBox(height: KitchenSpacing.lg),
          KitchenEmbossedButton(
            key: const ValueKey('check-delivery-zone-button'),
            onPressed: _onCheckZone,
            isLoading: checkoutState.isLoading,
            semanticLabel: 'Verifier la zone de livraison',
            child: Text(l10n.checkoutCheckZoneButton),
          ),
        ],
      ),
    );
  }

  _DeliveryStatusViewModel _deliveryStatusFor(CheckoutState state) {
    if (state.isLoading) {
      return const _DeliveryStatusViewModel(
        type: KitchenDeliveryStatusType.checking,
        title: 'Verification de la zone...',
        subtitle: 'Nous interrogeons la zone de livraison disponible.',
      );
    }
    if (state.error != null) {
      final isOutOfZone = state.error!.toLowerCase().contains('hors zone');
      return _DeliveryStatusViewModel(
        type: isOutOfZone
            ? KitchenDeliveryStatusType.invalid
            : KitchenDeliveryStatusType.error,
        title: state.error!,
        subtitle: isOutOfZone
            ? 'Vous pouvez basculer en retrait sans perdre votre panier.'
            : 'Verifiez votre connexion puis reessayez.',
      );
    }
    if (state.deliveryInfo != null) {
      return _DeliveryStatusViewModel(
        type: KitchenDeliveryStatusType.valid,
        title: 'Vous etes dans notre zone de livraison',
        subtitle:
            '${state.deliveryInfo!.name} - ${state.deliveryInfo!.estimatedMinutes} min',
      );
    }
    return const _DeliveryStatusViewModel(
      type: KitchenDeliveryStatusType.idle,
      title: 'Placez le repere sur la carte',
      subtitle: 'La validation utilise les coordonnees reelles du repere.',
    );
  }
}

class _DeliveryStatusViewModel {
  const _DeliveryStatusViewModel({
    required this.type,
    required this.title,
    this.subtitle,
  });

  final KitchenDeliveryStatusType type;
  final String title;
  final String? subtitle;
}
