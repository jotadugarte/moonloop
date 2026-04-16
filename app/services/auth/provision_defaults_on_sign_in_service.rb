module Auth
  class ProvisionDefaultsOnSignInService
    def initialize(user:)
      @user = user
    end

    def call
      ProvisionDefaultHabitsJob.perform_later(user_id: @user.id)
    end
  end
end
