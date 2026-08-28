import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/enums/data_origin.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/rates_list/rates_list_bloc.dart';
import '../widgets/rate_card.dart';
import '../widgets/shimmer_rate_card.dart';
import 'currency_detail_page.dart';

class RatesListPage extends StatelessWidget {
  const RatesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => sl<RatesListBloc>()..add(const RatesRequested()), child: const _RatesListView());
  }
}

class _RatesListView extends StatelessWidget {
  const _RatesListView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<RatesListBloc, RatesListState>(
      // Only fire when a refresh fails while rates are still on screen.
      // The prev-state guard prevents re-triggering if the state doesn't change.
      listenWhen: (prev, curr) =>
          curr.status == RatesListStatus.failure && curr.hasRates && prev.status != RatesListStatus.failure,
      listener: (context, state) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.failure!.message), backgroundColor: AppTheme.red));
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: _buildAppBar(state),
          body: Column(
            children: [
              _OfflineBanner(state: state),
              Expanded(child: _buildBody(context, state)),
            ],
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(RatesListState state) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('EGP Exchange Rates'),
          if (state.hasRates)
            Text(
              'Updated ${_formatDate(state.rates.first.rateDate)}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w400),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, RatesListState state) {
    // ── Initial loading: shimmer placeholder cards ──────────────────────────
    if (state.isInitialLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) => const ShimmerRateCard(),
      );
    }

    // ── No data + failure: full-screen error with retry ─────────────────────
    if (!state.hasRates && state.status == RatesListStatus.failure) {
      return _FullScreenError(
        failure: state.failure!,
        onRetry: () => context.read<RatesListBloc>().add(const RatesRequested()),
      );
    }

    // ── Rates available: list with pull-to-refresh ──────────────────────────
    // isRefreshing (rates present + loading) is handled by RefreshIndicator;
    // no extra UI is added on top of the list.
    return RefreshIndicator(
      color: AppTheme.green,
      backgroundColor: AppTheme.cardSurface,
      onRefresh: () async {
        final bloc = context.read<RatesListBloc>();
        bloc.add(const RatesRefreshed());
        // Hold the indicator until the BLoC finishes loading.
        await bloc.stream.firstWhere((s) => s.status != RatesListStatus.loading);
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.rates.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final rate = state.rates[i];
          return RateCard(
            rate: rate,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CurrencyDetailPage(rate: rate))),
          );
        },
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

// ── Offline banner ─────────────────────────────────────────────────────────────

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.state});

  final RatesListState state;

  @override
  Widget build(BuildContext context) {
    if (!state.hasRates) return const SizedBox.shrink();
    if (state.rates.first.dataOrigin != DataOrigin.cache) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: AppTheme.amber.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 13, color: AppTheme.amber),
          const SizedBox(width: 8),
          Text(
            'Offline · Cached data from '
            '${_RatesListView._formatDate(state.rates.first.rateDate)}',
            style: const TextStyle(color: AppTheme.amber, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Full-screen error ──────────────────────────────────────────────────────────

class _FullScreenError extends StatelessWidget {
  const _FullScreenError({required this.failure, required this.onRetry});

  final Failure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.signal_wifi_connected_no_internet_4_rounded, size: 56, color: AppTheme.textSecondary),
            const SizedBox(height: 16),
            Text(
              failure.message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
