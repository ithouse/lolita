class ::Integer
  def month_name in_month=false
    month=in_month ? "in_months" : "months"
    [
      :"#{month}.january",
      :"#{month}.february",
      :"#{month}.march",
      :"#{month}.april",
      :"#{month}.may",
      :"#{month}.june",
      :"#{month}.july",
      :"#{month}.august",
      :"#{month}.september",
      :"#{month}.october",
      :"#{month}.november",
      :"#{month}.december",
    ][self]
  end

  def week_day
    [
      :"days.monday",
      :"days.tuesday",
      :"days.wednesday",
      :"days.thursday",
      :"days.friday",
      :"days.saturday",
      :"days.sunday",
    ][self]
  end
end
