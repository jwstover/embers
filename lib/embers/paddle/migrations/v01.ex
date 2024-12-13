defmodule Embers.Paddle.Migrations.V01 do
  use Ecto.Migration

  def up(%{create_schema: create?, prefix: prefix} = opts) do
    %{quoted_prefix: quoted} = opts

    if create?, do: execute("CREATE SCHEMA IF NOT EXISTS #{quoted}")

    create table(:paddle_customers, primary_key: false, prefix: prefix) do
      add :id, :string, primary_key: true
      add :name, :string
      add :email, :string
      add :locale, :string
      add :status, :string
      add :created_at, :utc_datetime
      add :updated_at, :utc_datetime
      add :marketing_consent, :boolean, default: false, null: false
      add :custom_data, :map
      add :import_meta, :map

      add :user_id, references(:users, on_delete: :delete_all)
    end

    create_if_not_exists table(:paddle_subscriptions, primary_key: false, prefix: prefix) do
      add(:id, :string, primary_key: true)
      add(:status, :string)
      add(:paused_at, :utc_datetime)
      add(:created_at, :utc_datetime)
      add(:started_at, :utc_datetime)
      add(:updated_at, :utc_datetime)
      add(:canceled_at, :utc_datetime)
      add(:next_billed_at, :utc_datetime)
      add(:first_billed_at, :utc_datetime)
      add(:transaction_id, :string)
      add(:customer_id, references(:paddle_customers, type: :string, on_delete: :delete_all))
      add(:items, :map)
      add(:current_billing_period, :map)
    end

    create_if_not_exists(index(:paddle_subscriptions, [:customer_id], prefix: prefix))
  end

  def down(%{prefix: prefix}) do
    drop_if_exists(index(:paddle_subscriptions, [:customer_id], prefix: prefix))

    drop_if_exists(table(:paddle_subscriptions, prefix: prefix))
    drop_if_exists(table(:paddle_customers, prefix: prefix))
  end
end
