custom_recipe_data_initializer:
  type: world
  debug: false
  data:
    categories:
      travel:
        material: feather
        display: <element[Travel Items].color_gradient[from=#A303D4;to=#AAAAAA]>
        lore:
          - "<&e>Items related to getting around"
        title: <&chr[1011]>
      tools:
        material: feather
        display: <element[Tools].color_gradient[from=#A303D4;to=#AAAAAA]>
        lore:
          - "<&e>Items for getting work DONE!"
        title: <&chr[1012]>
      blocks:
        material: feather
        display: <element[Blocks].color_gradient[from=#17840b;to=#AAAAAA]>
        lore:
          - "<&e>Various custom blocks!"
        title: <&chr[1004]>
      combat:
        material: feather
        display: <element[Combat].color_gradient[from=#A303D4;to=#AAAAAA]>
        lore:
          - "<&e>Stuff to beat your friends!"
          - "<&e>Yea, probably your enemies too"
        title: <&chr[1006]>
      gadgets:
        material: feather
        display: <element[Gadgets].color_gradient[from=#bd770f;to=#AAAAAA]>
        lore:
          - "<&e>Cool things!"
          - "<&e>Other stuff, too..."
        title: <&chr[1009]>
      food:
        material: feather
        display: <element[Food].color_gradient[from=#bd770f;to=#AAAAAA]>
        lore:
          - "<&e>FEWD!!!!"
          - "<&e>Nom nom nom"
        title: <&chr[1008]>
      brewing:
        material: feather
        display: <element[Brewing].color_gradient[from=#bd770f;to=#AAAAAA]>
        lore:
          - "<&e>DRINKS!!!"
          - "<&e>You must be 21+ to click"
        title: <&chr[1005]>
      decor:
        material: feather
        display: <element[Decor].color_gradient[from=#17840b;to=#AAAAAA]>
        lore:
          - "<&e>Stuff for the pretty pretty!"
        title: <&chr[1007]>
      misc:
        material: feather
        display: "<element[Misc Items].color_gradient[from=#17840b;to=#AAAAAA]>"
        lore:
          - "<&e>Lotta random, ngl"
        title: <&chr[1010]>
  build_item_list:
    - flag server recipe_book:!
    - foreach <server.scripts.filter[data_key[data.recipe_book_category].exists].parse[name]> as:item_script:
      - if !<[item_script].as_item.recipe_ids.is_empty.if_null[true]>:
        - foreach <[item_script].as_item.recipe_ids> as:recipe_id:
          - define result <server.recipe_result[<[recipe_id]>]>
          - define items <list>
          - define category <[result].script.data_key[data.recipe_book_category].before[.]>
          - if !<script.data_key[data.categories].keys.contains[<[category]>]>:
            - debug ERROR "ITEM HAS UNKNOWN CATEGORY<&co> <[category]>"
            - foreach next
          - foreach <server.recipe_items[<[recipe_id]>]> as:recipe_item:
            - if <[recipe_item].starts_with[material]>:
              - define recipe_item <[recipe_item].substring[10].as_item>
            - else if <[recipe_item].script.data_key[recipes].exists>:
              - if <[recipe_item].lore.exists>:
                - define modified_lore "<[recipe_item].lore.include[<&b>Click to see Recipe]>"
              - else:
                - define modified_lore "<&b>Click to see Recipe"
              - define recipe_item <item[<[recipe_item]>].with[flag=category:<[category]>;flag=run_script:custom_recipe_inventory_open;flag=recipe_id:<[recipe_item].as_item.recipe_ids.get[1].after[<&co>]>;lore=<[modified_lore]>]>
            - else:
              - define value <[recipe_item].as_item>
            - define items:|:<[recipe_item]>
          - flag server recipe_book.categories.<[category]>.<[item_script]>:|:<[recipe_id].after[<&co>]>
          - flag server recipe_book.recipes.<[recipe_id].after[<&co>]>.items:!|:<[items]>
          - flag server recipe_book.recipes.<[recipe_id].after[<&co>]>.result:<[result]>
  events:
    on server start:
      - inject locally path:build_item_list
    on script reload:
      - inject locally path:build_item_list

custom_recipe_add_to_crafting:
  type: item
  material: paper
  display name: <&e>Learn Recipe
  lore:
    - "<&e>Add to Vanilla Crafting Book"
    - "<&7>This can fix uncraftable items"
  flags:
    run_script: custom_recipe_book_add_recipe
  mechanisms:
    custom_model_data: 108

custom_recipe_book_add_recipe:
  type: task
  debug: false
  script:
    - ratelimit <player> 1s
    - adjust <player> discover_recipe:denizen:<context.item.flag[recipe]>

custom_recipe_inventory_open:
  type: task
  debug: false
  definitions: recipe_id|page|category
  data:
    slots: 13|14|15|22|23|24|31|32|33
    result: 26
    back: 20
    next: 34
    previous: 30
    crafting_book_add: 35
  script:
    - define page 1 if:<[page].exists.not>
    - define recipe_id <context.item.flag[recipe_id]> if:<[recipe_id].exists.not>
    - define category <context.item.flag[category]> if:<[category].exists.not>
    - define recipe_id <[recipe_id]>
    - define inventory <inventory[custom_recipe_inventory]>
    - inventory set slot:<script.data_key[data.back]> d:<[inventory]> "o:feather[custom_model_data=3;display=<&c>Back to <[category].to_titlecase>;flag=category:<[category]>;flag=run_script:crafting_book_open_category]"
    - inventory set slot:<script.data_key[data.result]> d:<[inventory]> o:<server.flag[recipe_book.recipes.<[recipe_id]>.result].with[flag=page:<[page]>]>
    - inventory set slot:<script.data_key[data.crafting_book_add]> d:<[inventory]> o:custom_recipe_add_to_crafting[flag=recipe:<[recipe_id]>]
    - define slots <script.data_key[data.slots].as_list>
    - foreach <server.flag[recipe_book.recipes.<[recipe_id]>.items]>:
      - foreach next if:<[value].material.name.equals[air].if_null[false]>
      - inventory set slot:<[slots].get[<[loop_index]>]> d:<[inventory]> o:<[value]>

    # Add Recipe to Crafting Book

    # Next Page
    - define recipes <server.flag[recipe_book.recipes.<[recipe_id]>.result].recipe_ids.parse[after[<&co>]]>
    - if <[recipes].size> > <[page]>:
      - inventory set slot:<script.data_key[data.next]> o:<item[leather_horse_armor].with[hides=all;display=<&6>Next<&sp>Recipe;color=#baa68e;custom_model_data=7;flag=run_script:custom_recipe_inventory_nextpage;flag=recipe_id:<[recipes].get[<[page].add[1]>]>]> d:<[inventory]>

    # Previous Page
    - if <[page]> > 1:
      - inventory set slot:<script.data_key[data.previous]> o:<item[leather_horse_armor].with[hides=all;display=<&6>Previous<&sp>Recipe;color=#baa68e;custom_model_data=6;flag=run_script:custom_recipe_inventory_previouspage;flag=recipe_id:<[recipes].get[<[page].sub[1]>]>]> d:<[inventory]>

    - inventory open d:<[inventory]>

custom_recipe_inventory_nextpage:
  type: task
  debug: false
  script:
    - define page <context.inventory.slot[<script[custom_recipe_inventory_open].data_key[data.result]>].flag[page].add[1]>
    - define recipe_id <context.item.flag[recipe_id]>
    - define category <context.inventory.slot[<script[custom_recipe_inventory_open].data_key[data.back]>].flag[category]>
    - run custom_recipe_inventory_open def:<[recipe_id]>|<[page]>|<[category]>

custom_recipe_inventory_previouspage:
  type: task
  debug: false
  script:
    - define page <context.inventory.slot[<script[custom_recipe_inventory_open].data_key[data.result]>].flag[page].sub[1]>
    - define recipe_id <context.item.flag[recipe_id]>
    - define category <context.inventory.slot[<script[custom_recipe_inventory_open].data_key[data.back]>].flag[category]>
    - run custom_recipe_inventory_open def:<[recipe_id]>|<[page]>|<[category]>

crafting_book_inventory:
  type: inventory
  debug: false
  title: <&f><&font[adriftus:recipe_book]><&chr[F808]><&chr[1001]>
  size: 45
  gui: true
  inventory: chest

crafting_book_category_inventory:
  type: inventory
  debug: false
  title: <&f><&font[adriftus:recipe_book]><&chr[F808]><&chr[1002]>
  size: 36
  gui: true
  inventory: chest

custom_recipe_inventory:
  type: inventory
  debug: false
  title: <&f><&font[adriftus:recipe_book]><&chr[F808]><&chr[1003]>
  size: 36
  gui: true
  inventory: chest

crafting_book_open:
  type: task
  debug: false
  data:
    travel_slots: 11|12
    food_slots: 14|15
    blocks_slots: 17|18
    combat_slots: 20|21
    brewing_slots: 23|24
    decor_slots: 26|27
    tools_slots: 29|30
    gadgets_slots: 32|33
    misc_slots: 35|36
    back: 1
  script:
    - define inventory <inventory[crafting_book_inventory]>
    - foreach <script[custom_recipe_data_initializer].parsed_key[data.categories]> key:category as:values:
      # deleted from below ;lore=<[values].get[lore]>
      - define item <item[<[values].get[material]>].with[custom_model_data=3;display=<[values].get[display]>;flag=run_script:crafting_book_open_category;flag=category:<[category]>]>
      - foreach <script.data_key[data.<[category]>_slots]> as:slot:
        - inventory set slot:<[slot]> o:<[item]> d:<[inventory]>

    #Back to Main Menu
    - inventory set slot:<script.data_key[data.back]> d:<[inventory]> "o:<item[feather].with[flag=run_script:main_menu_inventory_open;custom_model_data=3;display=<&e>Back to Main Menu]>"

    - inventory open d:<[inventory]>

crafting_book_open_category:
  type: task
  debug: false
  data:
    slots: 11|12|13|14|15|16|17|20|21|22|23|24|25|26|29|30|31|32|33|34|35
    back_slot: 2
    next: 36
    previous: 28
  definitions: category|page
  script:
    - define page 1 if:<[page].exists.not>
    - define category <context.item.flag[category]> if:<[category].exists.not>
    - define inv <inventory[crafting_book_category_inventory]>
    - adjust <[inv]> title:<[inv].title><&font[adriftus:recipe_book]><&chr[F801]><&chr[F809]><&chr[F80A]><&chr[F80C]><script[custom_recipe_data_initializer].parsed_key[data.categories.<[category]>.title]>
    - define slots <script.data_key[data.slots].as_list>
    - inventory set slot:<script.data_key[data.back_slot]> d:<[inv]> "o:feather[custom_model_data=3;display=<&c>Back to Categories;flag=run_script:crafting_book_open;flag=page:<[page]>]"
    - if <server.has_flag[recipe_book.categories.<[category]>]>:
      - define items <server.flag[recipe_book.categories.<[category]>].keys.sort_by_value[as_item.script.data_key[data.recipe_book_category]]>
      - foreach <[items].get[<[page].sub[1].mul[<[slots].size>].add[1]>].to[<[page].mul[<[slots].size>]>]> as:item:
        - inventory set slot:<[slots].get[<[loop_index]>]> o:<item[<[item]>].with[flag=run_script:custom_recipe_inventory_open;flag=category:<[category]>;flag=recipe_id:<server.flag[recipe_book.categories.<[category]>.<[item]>].get[1]>]> d:<[inv]>

      # Next Page
      - if <[items].size> > <[page].mul[<[slots].size>]>:
        - inventory set slot:<script.data_key[data.next]> o:<item[leather_horse_armor].with[hides=all;display=<&6>Next<&sp>Page;color=#baa68e;custom_model_data=7;flag=run_script:custom_recipe_inventory_category_nextpage;flag=category:<[category]>]> d:<[inv]>

      # Previous Page
      - if <[page]> > 1:
        - inventory set slot:<script.data_key[data.previous]> o:<item[leather_horse_armor].with[hides=all;display=<&6>Previous<&sp>Page;color=#baa68e;custom_model_data=6;flag=run_script:custom_recipe_inventory_category_previouspage;flag=category:<[category]>]> d:<[inv]>

    - inventory open d:<[inv]>

custom_recipe_inventory_category_nextpage:
  type: task
  debug: false
  script:
    - define page <context.inventory.slot[<script[crafting_book_open_category].data_key[data.back_slot]>].flag[page].add[1]>
    - define category <context.item.flag[category]>
    - run crafting_book_open_category def:<[category]>|<[page]>

custom_recipe_inventory_category_previouspage:
  type: task
  debug: false
  script:
    - define page <context.inventory.slot[<script[crafting_book_open_category].data_key[data.back_slot]>].flag[page].sub[1]>
    - define category <context.item.flag[category]>
    - run crafting_book_open_category def:<[category]>|<[page]>