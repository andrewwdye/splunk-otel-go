module github.com/signalfx/splunk-otel-go/distro

go 1.20

require (
	github.com/go-logr/logr v1.4.1
	github.com/go-logr/zapr v1.3.0
	github.com/stretchr/testify v1.8.4
	github.com/tonglil/buflogr v1.1.1
	go.opentelemetry.io/contrib/instrumentation/runtime v0.48.0
	go.opentelemetry.io/contrib/propagators/autoprop v0.48.0
	go.opentelemetry.io/otel v1.23.1
	go.opentelemetry.io/otel/exporters/jaeger v1.17.0
	go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetricgrpc v1.23.1
	go.opentelemetry.io/otel/exporters/otlp/otlpmetric/otlpmetrichttp v1.23.1
	go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracegrpc v1.23.1
	go.opentelemetry.io/otel/exporters/otlp/otlptrace/otlptracehttp v1.23.1
	go.opentelemetry.io/otel/sdk v1.23.1
	go.opentelemetry.io/otel/sdk/metric v1.23.1
	go.opentelemetry.io/otel/trace v1.23.1
	go.opentelemetry.io/proto/otlp v1.1.0
	go.uber.org/goleak v1.3.0
	go.uber.org/zap v1.26.0
	google.golang.org/grpc v1.61.1
)

require (
	github.com/cenkalti/backoff/v4 v4.2.1 // indirect
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/go-logr/stdr v1.2.2 // indirect
	github.com/golang/protobuf v1.5.3 // indirect
	github.com/grpc-ecosystem/grpc-gateway/v2 v2.19.1 // indirect
	github.com/pmezard/go-difflib v1.0.0 // indirect
	go.opentelemetry.io/contrib/propagators/aws v1.23.0 // indirect
	go.opentelemetry.io/contrib/propagators/b3 v1.23.0 // indirect
	go.opentelemetry.io/contrib/propagators/jaeger v1.23.0 // indirect
	go.opentelemetry.io/contrib/propagators/ot v1.23.0 // indirect
	go.opentelemetry.io/otel/exporters/otlp/otlptrace v1.23.1 // indirect
	go.opentelemetry.io/otel/metric v1.23.1 // indirect
	go.uber.org/multierr v1.11.0 // indirect
	golang.org/x/net v0.21.0 // indirect
	golang.org/x/sys v0.17.0 // indirect
	golang.org/x/text v0.14.0 // indirect
	google.golang.org/genproto/googleapis/api v0.0.0-20240213162025-012b6fc9bca9 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20240213162025-012b6fc9bca9 // indirect
	google.golang.org/protobuf v1.32.0 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
)
