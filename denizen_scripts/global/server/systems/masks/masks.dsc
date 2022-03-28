masks_gui_command:
  type: command
  name: masks
  debug: false
  usage: /masks
  description: Used to access and change any unlocked masks.
  script:
    - if <context.args.size> < 1 || !<yaml[global.player.<player.uuid>].contains[masks.current.ability]>:
      - run cosmetic_selection_inventory_open def:masks
    - else if <context.args.get[1]> == ability:
      - run mask_ability_use

mask_ender_wizard:
  type: data
  display_data:
    category: Adriftus
    material: end_crystal
    display_name: <&6>Adriftus<&co> <&d>Ender Wizard
    description: "<&d>Free the End!"
  mask_data:
    id: ender_wizard
    display_name: <&d>Ender Wizard
    skin_blob: ewogICJ0aW1lc3RhbXAiIDogMTYzNjQ3MDc5MzY4NywKICAicHJvZmlsZUlkIiA6ICIwNTVhOTk2NTk2M2E0YjRmOGMwMjRmMTJmNDFkMmNmMiIsCiAgInByb2ZpbGVOYW1lIiA6ICJUaGVWb3hlbGxlIiwKICAic2lnbmF0dXJlUmVxdWlyZWQiIDogdHJ1ZSwKICAidGV4dHVyZXMiIDogewogICAgIlNLSU4iIDogewogICAgICAidXJsIiA6ICJodHRwOi8vdGV4dHVyZXMubWluZWNyYWZ0Lm5ldC90ZXh0dXJlL2Q0ZjdmYTA3YTdlOWY1NzU2ZWMxNGQ0YjUyYmIzNzk5ZjE2N2JkMTgxNjE2YmM5ODQ5ZmI5NGVkZjk1MTFmZjYiLAogICAgICAibWV0YWRhdGEiIDogewogICAgICAgICJtb2RlbCIgOiAic2xpbSIKICAgICAgfQogICAgfQogIH0KfQ==;BnPptUMoz6YAK1UVzGOipaY4a7U28aBhazRO5U7pToBuwMuH2b669AFM0T+/0d0LnmbzzHICFXv0npg+1NEoaCFfWf71koXXfJD/8lnO+ePlIWah7RrWWhha5gYY1UsUggGz7LJeUpieIqFIvRj+ZCF4Tu0nCSrN7O3FftVWWTyhL7CbxXhzlZ21MRwh2SfTDK+F4KdlUA5xfO5X+QL1RO6dSLZ91YHbf1xpkbJO5kxEmLDk77H5aoAUpM7us+FiKsxHDOLzRn6Cqmo4DvueONjWlK4jKuQciu0xDaeopZAgUJqojkdLzb2RGZfMTRmsUSP6g7TF9y1clJnjm165NnwlHG025ZOr0CLdOi/4HJHEHe+ug3h6P0RfKnszUae8flocQlt1vimgt71GgxGvQfdNs2DAKCA/5LeZXT9BZqbHf7AuTZ/KK0t6aSp1xgqETDCaOdgEnyclDQcg0LpV2elSPjyqOgT7A89F8LTAFAxxFrAKj2+BtM83C6BeGiFaAJowyqchDUQbfRhc04g9M8iTtSmacIj6bzLBeBRXjeR4Mqzdx1hfhUXXMzO2J9MMyx0/qOrtgbjDhV6iHyBihrNO3yjkcLJp3rfJa/1tVsvXbhSoGdCAFEuiDH3FGyQi0vzqazdedkLT7d8YnnkDQ0UvX6qfraRwsk1MzvZKYsM=

mask_wear_events:
  type: world
  debug: false
  initialize:
    - flag server masks:!
    - foreach <server.scripts.filter[name.starts_with[mask_]].filter[container_type.equals[DATA]]>:
      - flag server masks.categories.<[value].data_key[display_data.category]>.<[value].data_key[mask_data.id]>:<[value]>
      - flag server masks.ids.<[value].data_key[mask_data.id]>:<[value]>
  events:
    on player joins:
      - waituntil rate:10t <yaml.list.contains[global.player.<player.uuid>].or[<player.is_online.not>]>
      - if !<player.is_online>:
        - stop
      - if !<yaml[global.player.<player.uuid>].contains[defaults.skin_blob]> || <yaml[global.player.<player.uuid>].read[defaults.skin_blob]> != <player.skin_blob>:
        - run global_player_data_modify def:<player.uuid>|defaults.skin_blob|<player.skin_blob>
      - if <yaml[global.player.<player.uuid>].contains[masks.current]>:
        - adjust <player> skin_blob:<yaml[global.player.<player.uuid>].read[masks.current.skin_blob]>
        - rename t:<player> <yaml[global.player.<player.uuid>].read[masks.current.display_name]>
        - define mask_id <yaml[global.player.<player.uuid>].read[masks.current.id]>
        - define particle false
        - define item false
        - if <yaml[global.player.<player.uuid>].contains[masks.current.attachments]>:
          - run mask_attachment def:<yaml[global.player.<player.uuid>].read[masks.current.attachments]> save:queue
          - define item true
        - run network_map_update_name def:<player.uuid>|<yaml[global.player.<player.uuid>].read[masks.current.display_name]>
        - if <yaml[global.player.<player.uuid>].contains[masks.current.particle]>:
          - define particle true
        - if <[item]> || <[particle]>:
          - inject mask_loop

    on server start:
      - inject locally path:initialize
    on script reload:
      - inject locally path:initialize

mask_unlock:
  type: task
  debug: false
  definitions: mask_id
  script:
    - if <server.has_flag[masks.ids.<[mask_id]>]> && !<yaml[global.player.<player.uuid>].contains[masks.unlocked.<[mask_id]>]||false>:
      - run global_player_data_modify def:<player.uuid>|masks.unlocked.<[mask_id]>|true

mask_wear:
  type: task
  debug: false
  definitions: mask_id
  script:
      - determine passively cancelled
      - define mask_id <context.item.flag[cosmetic].if_null[default]> if:<[mask_id].exists.not>
      - if !<script[mask_<[mask_id]>].exists>:
        - debug error "UNKNOWN MASK<&co> <[mask_id]>"
        - stop
      - inventory close
      - wait 1t
      - define script <script[mask_<[mask_id]>]>
      - run global_player_data_modify def:<player.uuid>|masks.current|<[script].parsed_key[mask_data]>
      - adjust <player> skin_blob:<yaml[global.player.<player.uuid>].read[masks.current.skin_blob]>
      - rename t:<player> <yaml[global.player.<player.uuid>].read[masks.current.display_name]>
      - define particle false
      - define item false
      - if <yaml[global.player.<player.uuid>].contains[masks.current.attachments]>:
        - run mask_attachment def:<yaml[global.player.<player.uuid>].read[masks.current.attachments]> save:queue
        - define item true
      - run network_map_update_name def:<player.uuid>|<yaml[global.player.<player.uuid>].read[masks.current.display_name]>
      - if <yaml[global.player.<player.uuid>].contains[masks.current.particle]>:
        - define particle true
      - if <[item]> || <[particle]>:
        - inject mask_loop

mask_remove:
  type: task
  debug: false
  definitions: mask_id
  script:
    - determine passively cancelled
    - inventory close
    - wait 1t
    - run global_player_data_modify def:<player.uuid>|masks.current|!
    - adjust <player> skin_blob:<yaml[global.player.<player.uuid>].read[defaults.skin_blob]>
    - rename t:<player> <player.name>
    - kill <player.passenger> if:<player.passenger.entity_type.equals[armor_stand].if_null[false]>
    - remove <player.passenger> if:<player.passenger.entity_type.equals[armor_stand].if_null[false]>
    - run network_map_update_name def:<player.uuid>|<player.name>

mask_attachment:
  type: task
  debug: false
  definitions: item_map
  script:
    - define off_hand <[item_map].get[offhand].if_null[air]>
    - define main_hand <[item_map].get[mainhand].if_null[air]>
    - define pose <map[left_arm=0,0,0;right_arm=0,0,0]>
    - spawn armor_stand[armor_pose=<[pose]>;marker=true;visible=false;equipment=<[item_map]>;item_in_offhand=<[off_hand]>;item_in_hand=<[main_hand]>]] <player.location> save:as
    - mount <entry[as].spawned_entity>|<player>
    - flag <entry[as].spawned_entity> on_dismount:cancel
    - flag <entry[as].spawned_entity> on_entity_added:remove_this_entity
    - determine <entry[as].spawned_entity>

mask_loop:
  type: task
  debug: false
  definitions: item|particle
  script:
    # Get armor stand, if mask has attached item
    - if <[item]>:
      - define armor_stand <entry[queue].created_queue.determination.get[1]>

    # Define Particle Data, if applicable
    - if <[particle]>:
      - define rate <yaml[global.player.<player.uuid>].read[masks.current.particle.rate]>
      - define effect <yaml[global.player.<player.uuid>].read[masks.current.particle.effect]>
      - define quantity <yaml[global.player.<player.uuid>].read[masks.current.particle.quantity]>
      - define offset <yaml[global.player.<player.uuid>].read[masks.current.particle.offset]>
      - define targets <player.location.find_players_within[50]>

    # Item Rotation Without Particles
    - if <[item]> && !<[particle]>:
      - while <player.is_online> && <yaml[global.player.<player.uuid>].read[masks.current.id]> == <[mask_id]>:
        - look <[armor_stand]> yaw:<player.location.yaw>
        - wait 1t
      - kill <[armor_stand]>
      - remove <[armor_stand]>

    # Item Rotation and Particles
    - else if <[item]> && <[particle]>:
      - while <player.is_online> && <yaml[global.player.<player.uuid>].read[masks.current.id]> == <[mask_id]>:
        # Every 2 seconds we run range checks for particles
        - if <[loop_index].mod[40]> == 0:
          - define targets <player.location.find_players_within[50]>
        - if <[loop_index].mod[<[rate]>]> == 0:
          - playeffect at:<player.location.above> effect:<[effect]> offset:<[offset]> quantity:<[quantity]> targets:<[targets]>
        - look <[armor_stand]> yaw:<player.location.yaw>
        - wait 1t
      - kill <[armor_stand]>
      - remove <[armor_stand]>

    # Particles without Item Rotation
    - else if !<[item]> && <[particle]>:
      - define modulo_rate <element[40].div[<[rate]>]>
      - while <player.is_online> && <yaml[global.player.<player.uuid>].read[masks.current.id]> == <[mask_id]>:
        # ROUGHLY every 2 seconds we run range checks for particles
        - if <[loop_index].mod[<[modulo_rate]>]> == 0:
          - define targets <player.location.find_players_within[50]>
        - playeffect at:<player.location.above> effect:<[effect]> offset:<[offset]> quantity:<[quantity]> targets:<[targets]>
        - wait <[rate]>t

mask_ability_use:
  type: task
  debug: false
  script:
    - if <yaml[global.player.<player.uuid>].contains[masks.current.ability]>:
      - run <yaml[global.player.<player.uuid>].read[masks.current.ability.task]>