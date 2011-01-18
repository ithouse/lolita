class Lolita::AdminAbility
  def initialize(user)
    if user.is_a?(Lolita::Admin)
      can :manage, :all
    end
  end
end
