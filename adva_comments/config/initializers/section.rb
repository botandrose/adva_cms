class SectionFormBuilder < ExtensibleFormBuilder
  before(:section, :submit_buttons) do |f|
    unless @section.type == 'Forum'
      render :partial => 'admin/sections/comments_settings', :locals => { :f => f }
    end
  end

  ActiveSupport::Reloader.to_prepare do
    Section.class_eval do
      def accept_comments?
        true
      end
    end
  end
end
