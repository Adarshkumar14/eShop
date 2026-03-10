using System.Text.Json.Serialization;
using eShop.OrderProcessor.Events;

namespace eShop.OrderProcessor.Extensions;

public static class Extensions
{
    public static void AddApplicationServices(this IHostApplicationBuilder builder)
    {
        // TEMPORARILY DISABLED FOR .NET 9 COMPATIBILITY - RabbitMQ.Client API breaking changes
        // builder.AddRabbitMqEventBus("eventbus")
        //        .ConfigureJsonOptions(options => options.TypeInfoResolverChain.Add(IntegrationEventContext.Default));

        builder.AddNpgsqlDataSource("orderingdb");

        builder.Services.AddOptions<BackgroundTaskOptions>()
            .BindConfiguration(nameof(BackgroundTaskOptions));

        builder.Services.AddHostedService<GracePeriodManagerService>();
    }
}

[JsonSerializable(typeof(GracePeriodConfirmedIntegrationEvent))]
partial class IntegrationEventContext : JsonSerializerContext
{

}
