class Customisation::BuyCustomisation
  def initialize(user, customisation)
    @user = user
    @customisation = customisation
  end

  def call
    return error_openstruct('Customisation not found') unless @customisation.present?
    return error_openstruct('You do not have enough points') unless funds_present?
    return unless @user.present?

    purchase
    @user.save
    OpenStruct.new(success?: true, user: @user, errors: nil)
  end

  def funds_present?
    @user.challenge_points >= @customisation.cost
  end

  def purchase
    @user.challenge_points -= @customisation.cost
    purchase_dashboard_style if @customisation.dashboard_style?
    purchase_leaderboard_icon if @customisation.leaderboard_icon?
  end

  def purchase_dashboard_style
    @user.dashboard_style = @customisation.value
  end

  def error_openstruct(error)
    OpenStruct.new(success?: false, user: @user, errors: error)
  end
end
