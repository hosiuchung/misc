using Castle.DynamicProxy;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;
using System;
using System.Reflection;
using System.Threading.Tasks;

namespace AbpDemo.AOP.Redis
{
    public class RedisExceptionInterceptor : IInterceptor
    {
        private readonly ILogger<RedisExceptionInterceptor> _logger;

        public RedisExceptionInterceptor(ILogger<RedisExceptionInterceptor> logger)
        {
            _logger = logger;
        }

        public void Intercept(IInvocation invocation)
        {
            // Target is async method without return value
            if (invocation.Method.ReturnType == typeof(Task))
            {
                invocation.ReturnValue = InterceptAsync(invocation);
            }
            // Target is async method with return value
            else if (invocation.Method.ReturnType.IsGenericType
                && invocation.Method.ReturnType.GetGenericTypeDefinition() == typeof(Task<>))
            {
                var genericType = invocation.Method.ReturnType.GenericTypeArguments[0];

                // Invoke generic method InterceptAsync
                invocation.ReturnValue = GetType()
                    .GetMethod(
                        name: nameof(InterceptAsync),
                        genericParameterCount: 1,
                        bindingAttr: BindingFlags.Instance | BindingFlags.NonPublic,
                        binder: null,
                        types: new Type[] { typeof(IInvocation) },
                        modifiers: null)
                    .MakeGenericMethod(genericType) // Set type param
                    .Invoke(this, new object[] { invocation });
            }
            // Target is not async method
            else
            {
                try
                {
                    invocation.Proceed();
                }
                catch (Exception ex) when (ex is RedisTimeoutException or RedisConnectionException)
                {
                    _logger.LogError(ex.ToString());
                    // Return null if return type is reference type or void, else create instance for returning (value type)
                    invocation.ReturnValue =
                        (invocation.Method.ReturnType.IsValueType && invocation.Method.ReturnType != typeof(void))
                        ? Activator.CreateInstance(invocation.Method.ReturnType)
                        : null;
                }
            }
        }

        private async Task InterceptAsync(IInvocation invocation)
        {
            try
            {
                invocation.Proceed();
                var task = (Task)invocation.ReturnValue;
                await task;
            }
            catch (Exception ex) when (ex is RedisTimeoutException or RedisConnectionException)
            {
                _logger.LogError(ex.ToString());
            }
        }

        private async Task<T> InterceptAsync<T>(IInvocation invocation)
        {
            try
            {
                invocation.Proceed();
                var task = (Task<T>)invocation.ReturnValue;
                return await task;
            }
            catch (Exception ex) when (ex is RedisTimeoutException or RedisConnectionException)
            {
                _logger.LogError(ex.ToString());
                return default; // The default value of T
            }
        }
    }
}
