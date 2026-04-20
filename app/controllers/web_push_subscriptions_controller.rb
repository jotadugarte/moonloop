class WebPushSubscriptionsController < ApplicationController
  def create
    sub = Current.user.web_push_subscriptions.find_or_initialize_by(endpoint: subscription_params.fetch(:endpoint))
    sub.assign_attributes(subscription_params)

    if sub.save
      render json: { ok: true }, status: :ok
    else
      render json: { ok: false, errors: sub.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    sub = Current.user.web_push_subscriptions.find_by(endpoint: params.require(:endpoint))
    sub&.destroy!
    render json: { ok: true }, status: :ok
  end

  private

  def subscription_params
    params.require(:subscription).permit(:endpoint, :p256dh, :auth)
  end
end
