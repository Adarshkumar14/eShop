var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

// TEMPORARILY DISABLED FOR .NET 9 COMPATIBILITY - RabbitMQ.Client API breaking changes
// builder.AddRabbitMqEventBus("EventBus")
//     .AddSubscription<OrderStatusChangedToStockConfirmedIntegrationEvent, OrderStatusChangedToStockConfirmedIntegrationEventHandler>();

builder.Services.AddOptions<PaymentOptions>()
    .BindConfiguration(nameof(PaymentOptions));

var app = builder.Build();

app.MapDefaultEndpoints();

await app.RunAsync();
