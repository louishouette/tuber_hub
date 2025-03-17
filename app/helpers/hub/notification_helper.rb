module Hub
  module NotificationHelper
    def notification_css_class(notification_type)
      case notification_type.to_s
      when 'info' then 'bg-blue-100 text-blue-800 dark:bg-blue-900 dark:text-blue-300'
      when 'success' then 'bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-300'
      when 'warning' then 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-300'
      when 'error' then 'bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-300'
      else 'bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-300'
      end
    end
    
    def notification_icon(notification_type)
      case notification_type.to_s
      when 'info'
        tag.svg(class: "w-5 h-5") do
          tag.path(fill_rule: "evenodd", d: "M2 10a8 8 0 1116 0 8 8 0 01-16 0zm8-9a9 9 0 100 18A9 9 0 0010 1zm0 5a1 1 0 011 1v3a1 1 0 11-2 0V7a1 1 0 011-1zm0 9a1 1 0 100-2 1 1 0 000 2z", clip_rule: "evenodd")
        end
      when 'success'
        tag.svg(class: "w-5 h-5") do
          tag.path(fill_rule: "evenodd", d: "M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z", clip_rule: "evenodd")
        end
      when 'warning'
        tag.svg(class: "w-5 h-5") do
          tag.path(fill_rule: "evenodd", d: "M8.257 3.099c.765-1.36 2.722-1.36 3.486 0l5.58 9.92c.75 1.334-.213 2.98-1.742 2.98H4.42c-1.53 0-2.493-1.646-1.743-2.98l5.58-9.92zM11 13a1 1 0 11-2 0 1 1 0 012 0zm-1-8a1 1 0 00-1 1v3a1 1 0 002 0V6a1 1 0 00-1-1z", clip_rule: "evenodd")
        end
      when 'error'
        tag.svg(class: "w-5 h-5") do
          tag.path(fill_rule: "evenodd", d: "M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z", clip_rule: "evenodd")
        end
      else
        tag.svg(class: "w-5 h-5") do
          tag.path(d: "M14 1a1 1 0 011 1v12a1 1 0 01-1 1H2a1 1 0 01-1-1V2a1 1 0 011-1h12zM2 0a2 2 0 00-2 2v12a2 2 0 002 2h12a2 2 0 002-2V2a2 2 0 00-2-2H2z")
          tag.path(d: "M8 4a.5.5 0 01.5.5v3h3a.5.5 0 010 1h-3v3a.5.5 0 01-1 0v-3h-3a.5.5 0 010-1h3v-3A.5.5 0 018 4z")
        end
      end
    end
    
    def time_ago(datetime)
      return '' if datetime.nil?
      
      time_ago_in_words(datetime) + ' ago'
    end
  end
end
