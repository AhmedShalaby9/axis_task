# Project Structure

High-level map of the feature-based layout. Every named box is a Dart file or directory that exists in `lib/`.

![Project Structure](project_structure.svg)

```mermaid
graph TD
    subgraph lib["lib/"]
        main["main.dart\n(bootstrap + DI init)"]

        subgraph core["core/"]
            direction TB
            constants["constants/\napp_constants.dart\n(target currencies, API URL)"]
            enums["enums/\ndata_origin.dart"]
            errors["error/\nexceptions.dart · failures.dart"]
            network["network/\nnetwork_info.dart"]
            theme["theme/\napp_theme.dart"]
            usecase_base["usecase/\nusecase.dart · NoParams"]
            di["di/\ninjection_container.dart\nmodules: network · currency"]
        end

        subgraph features["features/currency/"]
            direction TB

            subgraph domain["domain/"]
                entities["entities/\nexchange_rate · rate_history\negp_trend · data_origin"]
                repo_contract["repositories/\ncurrency_repository.dart"]
                usecases["usecases/\nget_all_rates_with_change\nget_rate_history"]
            end

            subgraph data["data/"]
                models["models/\ncurrency_rate_model.dart\n(fromJson · toJson)"]
                remote["datasources/\ncurrency_remote_datasource"]
                local["datasources/\ncurrency_local_datasource\n(SharedPreferences)"]
                repo_impl["repositories/\ncurrency_repository_impl\n(inversion · cache fallback)"]
            end

            subgraph presentation["presentation/"]
                subgraph blocs["bloc/"]
                    rates_bloc["rates_list/\nRatesListBloc\nRatesListState\nRatesListEvent"]
                    detail_bloc["currency_detail/\nCurrencyDetailBloc\nCurrencyDetailState"]
                end
                subgraph pages_dir["pages/"]
                    rates_page["RatesListPage"]
                    detail_page["CurrencyDetailPage"]
                end
                subgraph widgets_dir["widgets/"]
                    card["rate_card.dart"]
                    badge["change_badge.dart"]
                    chart["seven_day_chart.dart"]
                    shimmer_w["shimmer_card.dart"]
                end
            end
        end
    end

    main --> di
    di --> network
    di --> repo_impl
    di --> rates_bloc
    di --> detail_bloc

    rates_bloc --> usecases
    detail_bloc --> usecases
    usecases --> repo_contract
    repo_impl --> repo_contract
    repo_impl --> remote
    repo_impl --> local
    repo_impl --> models

    rates_page --> rates_bloc
    rates_page --> card
    card --> badge
    detail_page --> detail_bloc
    detail_page --> chart
```

### Layer responsibilities

| Layer | Responsibility | Key rule |
|---|---|---|
| **domain** | Entities + use-case contracts | No Flutter, no http, no SharedPreferences |
| **data** | HTTP, cache, rate inversion | Returns `Either<Failure, T>`; never throws past the boundary |
| **presentation** | BLoC + widgets | Only calls use cases; never touches `http` or `SharedPreferences` directly |
| **core** | Shared primitives | No feature-specific logic |
