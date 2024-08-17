# == Schema Information
#
# Table name: cached_counts
#
#  id         :integer          not null, primary key
#  count      :integer
#  model      :string
#  scope      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_cached_counts_on_model_and_scope  (model,scope) UNIQUE
#
class CachedCount < ApplicationRecord
end
