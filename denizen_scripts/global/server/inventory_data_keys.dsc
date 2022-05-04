inventory_data_keys:
  type: world
  debug: true
  events:
    on player closes inventory:
      - if <context.inventory.script.data_key[data.on_close].exists>:
        - inject <context.inventory.script.data_key[data.on_close]>
    on player clicks in inventory bukkit_priority:HIGHEST:
      - stop if:<context.inventory.script.data_key[data.clickable_slots].exists.not>
      - if <context.inventory.script.data_key[data.clickable_slots].contains[<context.slot>]>:
        - determine cancelled:false