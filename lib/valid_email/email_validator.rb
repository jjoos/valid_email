require 'active_model'
require 'active_model/validations'

class EmailValidator < ActiveModel::EachValidator
  def validate_each(record,attribute,value)
    return if options[:allow_nil] && value.nil?
    return if options[:allow_blank] && value.blank?

    r = ValidEmail.validate_parseable(value)

    if r && options[:mx]
      require 'valid_email/mx_validator'
      r &&= MxValidator.new(:attributes => attributes).validate(record)
    end

    record.errors.add attribute, (options[:message] || I18n.t(:invalid, :scope => "valid_email.validations.email")) unless r
  end
end

module ValidEmail
  def self.validate_parseable(email_address)
    require 'mail'

    m = Mail::Address.new(email_address)
    # We must check that value contains a domain and that value is an email address
    return false unless m.domain && m.address == email_address
    t = m.__send__(:tree)
    # We need to dig into treetop
    # A valid domain must have dot_atom_text elements size > 1
    # user@localhost is excluded
    # treetop must respond to domain
    # We exclude valid email values like <user@localhost.com>
    # Hence we use m.__send__(tree).domain
    return false unless t.domain.dot_atom_text.elements.size > 1

    # check if the domain contains only word chars and dots and dashes in between word chars
    return m.domain =~ /\A(?:\w+(?:\-+\w+)*\.)*(?:[a-z0-9][a-z0-9-]*[a-z0-9])\Z/i
  rescue
    false
  end
end
