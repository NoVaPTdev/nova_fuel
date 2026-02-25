# nova_fuel

Sistema de combustível para NOVA Framework. Postos de abastecimento, jerrycans e consumo por veículo.

## Dependências

- **nova_core** (obrigatório)
- **nova_notify** (notificações ao abastecer)

## Instalação

1. Coloca a pasta `nova_fuel` em `resources/[nova]/`.
2. No `server.cfg`:

```cfg
ensure nova_core
ensure nova_notify
ensure nova_fuel
```

## Configuração

Em `config.lua` configuras preços, consumo, postos (coordenadas), item de jerrycan e mensagens.

## Estrutura

- `client/main.lua` — lógica de abastecimento e consumo
- `client/stations.lua` — postos de combustível
- `client/jerrycan.lua` — uso de jerrycan
- `server/main.lua` — persistência e validação
- `config.lua` — configuração
- `html/` — NUI do posto

## Documentação

[NOVA Framework Docs](https://github.com/NoVaPTdev).

## Licença

Parte do ecossistema NOVA Framework.
