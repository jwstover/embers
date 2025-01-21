defmodule Embers.Paddle do
  @moduledoc """
  Functions for interacting with Paddle for payment processing.
  """

  require Logger

  def config do
    Application.get_env(:embers, Paddle)
  end

  def endpoint do
    config()[:endpoint]
  end

  def api_key do
    config()[:api_key]
  end

  def client_token do
    config()[:client_token]
  end

  def environment do
    config()[:environment]
  end

  def request(method, path, options \\ []) do
    url = Path.join(endpoint(), path)
    auth_header = {"Authorization", "Bearer #{api_key()}"}
    headers = Keyword.get(options, :headers, []) ++ [auth_header]
    options = Keyword.merge(options, method: method, url: url, headers: headers)

    Req.request(options)
  end

  defp handle_resp(req_response, success_code, msg) do
    case req_response do
      {:ok, %{status: ^success_code, body: %{"data" => data}}} ->
        {:ok, data}

      {_, err} ->
        msg && Logger.error("#{msg}: #{inspect(err)}")
        {:error, err}
    end
  end

#╭──────────────────────────────────────────────────────────────────────────────╮
#│                                  CUSTOMERS                                   │
#╰──────────────────────────────────────────────────────────────────────────────╯

  def create_customer(email) do
    body = %{email: email} |> Jason.encode!()

    path = "/customers"

    request(:post, path, body: body)
    |> handle_resp(201, "Failed creating new customer")
  end

  def get_portal_session_url(customer_id, subscription_ids \\ []) do
    body = %{subscription_ids: subscription_ids} |> Jason.encode!()

    path = Path.join(["/customers", customer_id, "portal-sessions"])
    request(:post, path, body: body)
    |> handle_resp(201, "Failed to get customer portal session link")
  end

  def list_customers(opts \\ []) do
    query_params = URI.encode_query(opts)

    path = "/customers?#{query_params}"

    request(:get, path)
    |> handle_resp(200, "Failed retrieving paddle customers")
  end

#╭──────────────────────────────────────────────────────────────────────────────╮
#│                                   PRODUCTS                                   │
#╰──────────────────────────────────────────────────────────────────────────────╯

  def list_products(opts \\ []) do
    query_params = URI.encode_query(opts)

    path = "/products?#{query_params}"

    request(:get, path)
    |> handle_resp(200, "Failed retrieving paddle products")
  end

#╭──────────────────────────────────────────────────────────────────────────────╮
#│                                    PRICES                                    │
#╰──────────────────────────────────────────────────────────────────────────────╯

  def list_prices(opts \\ []) do
    query_params = URI.encode_query(opts)

    path = "/prices#{query_params}"

    request(:get, path)
    |> handle_resp(200, "Failed retrieving paddle prices")
  end

  def get_price(price_id) do
    path = "/prices/#{price_id}"

    request(:get, path)
    |> handle_resp(200, "Failed retrieving paddle price")
  end

#╭──────────────────────────────────────────────────────────────────────────────╮
#│                                SUBSCRIPTIONS                                 │
#╰──────────────────────────────────────────────────────────────────────────────╯

  def get_subscription(subscription_id) do
    request(:get, "/subscriptions/#{subscription_id}")
    |> handle_resp(200, "Failed to get subscription")
  end

  def list_subscriptions(params \\ %{}) do
    query = URI.encode_query(params)

    request(:get, "/subscriptions?#{query}")
    |> handle_resp(200, "Failed to list subscriptions")
  end

  def maybe_reinstate_subscription(subscription) do
    get_subscription(subscription.id)
    |> case do
      {:ok, %{"status" => status, "scheduled_change" => %{"action" => "cancel"}}} when status in ["active", "trialing"] ->
        {:ok, _} = update_subscription(subscription.id, %{scheduled_change: nil})
        :ok

      _ ->
        :ok
    end
  end

  def update_subscription(subscription_id, params) do
    body = params |> Jason.encode!()

    request(:patch, "/subscriptions/#{subscription_id}", body: body)
    |> handle_resp(200, "Failed to update subscription")
  end

  def cancel_subscription(subscription_id) do
    path = "/subscriptions/#{subscription_id}/cancel"

    body = """
    {"effective_from": "next_billing_period"}
    """

    request(:post, path, body: body)
    |> handle_resp(200, "Failed updating subscription")
  end

  def remove_subscription_change(subscription_id) do
    path = "/subscriptions/#{subscription_id}"

    body = """
    {"scheduled_change": null}
    """

    request(:patch, path, body: body)
    |> handle_resp(200, "Failed updating subscription")
  end
end
