module RailsSettings
  module Base
    def self.included(base)
      base.class_eval do
        has_many :setting_objects,
                 as: :target,
                 autosave: true,
                 dependent: :delete_all,
                 class_name: setting_object_class_name

        def settings(var)
          raise ArgumentError unless var.is_a?(Symbol)
          raise ArgumentError, "Unknown key: #{var}" unless self.class.default_settings[var]

          if RailsSettings.can_protect_attributes?
            setting_objects.detect do |s|
              s.var == var.to_s
            end || setting_objects.build({ value: self.class.default_settings[var] }, without_protection: true)
          else
            setting_objects.detect { |s| s.var == var.to_s } || setting_objects.build( value: self.class.default_settings[var] )
          end
        end

        def settings=(value)
          if value.nil?
            setting_objects.each(&:mark_for_destruction)
          else
            raise ArgumentError
          end
        end

        def settings?(var = nil)
          if var.nil?
            setting_objects.any? do |setting_object|
              !setting_object.marked_for_destruction? && setting_object.value.present?
            end
          else
            settings(var).value.present?
          end
        end

        def to_settings_hash
          settings_hash = self.class.default_settings.dup
          settings_hash.each do |var, _vals|
            settings_hash[var] = settings_hash[var].merge(settings(var.to_sym).value)
          end
          settings_hash
        end
      end
    end
  end
end
