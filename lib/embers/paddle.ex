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

  def request(method, path, options \\ []) do
    url = Path.join(endpoint(), path)
    auth_header = {"Authorization", "Bearer #{api_key()}"}
    headers = Keyword.get(options, :headers, []) ++ [auth_header]
    options = Keyword.merge(options, method: method, url: url, headers: headers)

    Req.request(options)
  end

  defp handle_resp(req_response, success_code, msg) do
    case req_response do
      {:ok, %{status: ^success_code, body: body}} ->
        {:ok, body}

      {_, err} ->
        msg && Logger.error("#{msg}: #{inspect(err)}")
        {:error, err}
    end
  end

  def create_customer(email) do
    body = %{email: email} |> Jason.encode!()

    path = "/customers"

    request(:post, path, body: body)
    |> handle_resp(201, "Failed creating new customer")
  end

  def list_customers(opts \\ []) do
    query_params = URI.encode_query(opts)

    path = "/customers?#{query_params}"

    request(:get, path)
    |> handle_resp(200, "Failed retrieving paddle customers")
  end

  def list_products(opts \\ []) do
    query_params = URI.encode_query(opts)

    path = "/products?#{query_params}"

    request(:get, path)
    |> handle_resp(200, "Failed retrieving paddle products")
  end

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
