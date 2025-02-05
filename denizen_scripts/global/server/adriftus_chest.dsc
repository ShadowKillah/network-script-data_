adriftus_chest_inventory_open:
  type: task
  debug: false
  script:
    - define inventory <inventory[adriftus_chest_inventory]>
    - foreach <yaml[global.player.<player.uuid>].read[adriftus.chest.contents_map]||<map>>:
      - inventory set slot:<[key]> o:<[value]> d:<[inventory]>
    - inventory open d:<[inventory]>

adriftus_chest_inventory:
  type: inventory
  inventory: chest
  title: <&f><&font[adriftus:guis]><&chr[F808]><&chr[6930]>
  size: 45

adriftus_chest_inventory_events:
  type: world
  debug: false
  events:
    on player closes adriftus_chest_inventory:
      - define contents <context.inventory.map_slots>
      - define map <map>
      - foreach <[contents]> key:slot as:item:
        - if <[item].has_flag[adriftus.server.bypass]>:
          - define map <[map].with[<[slot]>].as[<[item]>]>
        - else if !<[item].has_flag[adriftus_server]>:
          - define server_name <server.flag[display_name]||<&6><bungee.server.replace[_].with[<&sp>].to_titlecase>>
          - define lore "<[item].lore.include[<&e>Server<&co> <[server_name]>]||<&e>Server<&co> <[server_name]>>"
          - define map <[map].with[<[slot]>].as[<[item].with[lore=<[lore]>;flag=adriftus_server:<bungee.server>;flag=run_script:adriftus_chest_validate]>]>
        - else:
          - define map <[map].with[<[slot]>].as[<[item]>]>
      - run global_player_data_modify def:<player.uuid>|adriftus.chest.contents_map|<[map]>

adriftus_chest_validate:
  type: task
  debug: false
  script:
    - if <bungee.server> == hub:
      - stop
    - if <context.item.has_flag[adriftus_server]> && <context.item.flag[adriftus_server]> != <bungee.server> && <server.flag[linked_servers].contains[<context.item.flag[adriftus_server]>].if_null[false].not> && <context.item.flag[adriftus_server]> != hub:
      - determine cancelled
    - else:
      - define lore <context.item.lore.remove[last]>
      - determine <context.item.with[lore=<[lore]>;flag=run_script:!;flag=adriftus_server:!]>