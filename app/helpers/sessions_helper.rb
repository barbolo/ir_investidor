module SessionsHelper
  def checklist_class(step, previous_step)
    if previous_step == true
      case step
      when nil
        'loading'
      when false
        'error'
      when true
        'done'
      end
    else
      'pending'
    end
  end

  def checklist_fa_class(step, previous_step)
    if previous_step == true
      case step
      when nil
        'fas fa-spinner fa-pulse'
      when false
        'fas fa-square'
      when true
        'fas fa-check-square'
      end
    else
      'far fa-square'
    end
  end
end
