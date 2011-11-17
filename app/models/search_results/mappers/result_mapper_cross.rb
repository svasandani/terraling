module SearchResults

  module Mappers
    class ResultMapperCross < ResultMapper

      def self.build_result_groups(result)

        vals = LingsProperty.with_id(vals_ids_for_cross(result))
        vals_by_prop_ids = vals_by_property_id(vals)

        prop_values = [].tap do |p|
          vals_by_prop_ids.keys.each do |prop_id|
            p << vals_by_prop_ids[prop_id].map(&:property_value).uniq
          end
        end

        first_prop = prop_values.first
        rest_props = prop_values.drop(1)

        combinations = first_prop.product(*rest_props)

        combinations.each do |c|
          c.map! do |prop_value|
            LingsProperty.find_by_property_value(prop_value)
          end
        end

        {}.tap do |groups|
          combinations.map do |comb_parents|
            comb_parent_ids = comb_parents.map {|p| p.id.to_i}
            groups[comb_parent_ids] = lings_ids_in_combination(vals, comb_parents)
          end
          groups["type"]="cross"
        end
      end

      def to_flatten_results
        @flatten_results ||= [].tap do |entry|
          result_groups.each do |parent_ids, children_ids|
            parent           = parents.select {|parent| parent.map(&:id).sort == parent_ids.sort }.flatten
            related_children = children.select {|child| child.map(&:ling_id).sort == children_ids.sort }.flatten
            entry << ResultEntry.new(parent, related_children)
          end
        end
      end

      def parents
        @parents ||= [].tap do |parent|
          parent_ids.each do |parent_id|
            parent << LingsProperty.with_id(parent_id).joins(:property).includes([:property]).order("properties.name")
          end
        end
      end

      def children
        @children ||= [].tap do |child|
          all_child_ids.each do |children_ids|
            lings = children_by_lings(children_ids)
            child << lings if lings.any?
          end
        end
      end

      private

      def children_by_lings(children_ids)
        ling_props = LingsProperty.with_ling_id(children_ids).joins(:ling, :property).includes([:ling, :property]).order("lings.name").to_a.group_by {|lp| lp.ling }
        ling_props.keys.map {|ling| ling_props[ling].first}
      end

      def self.depth_for_cross(result)
        result.depth_for_cross
      end

      def self.vals_ids_for_cross(result)
        is_parent?(depth_for_cross(result)) ? result.parent : result.child
      end

      def self.vals_by_ling_id(vals)
        vals.group_by { |v| v.ling_id }
      end

      def self.lings_ids_in_combination(vals, combination)
        lings_ids = vals_by_ling_id(vals)

        lings_ids.select do |ling|
          combination.map {|lp| lp.property_value.to_s}.
              all? { |value| ling_with_combination?(lings_ids[ling], value) }
        end.keys
      end

      def self.ling_with_combination?(ling_props, value)
        ling_props.select { |lp| lp.property_value == value}.any?
      end

    end
  end
end