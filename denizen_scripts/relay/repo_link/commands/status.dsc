status_command_create:
  type: task
  debug: true
  script:
    - definemap options:
        1:
          type: string
          name: server
          description: Specifies a server to check the status for
          #, default returning them all
          required: true
        #additional option templates
        #2:
        #  type: boolean
        #  name: help
        #  description: Shows helpful information on how you can use this command
        #  required: false
        #3:
        #  type: boolean
        #  name: players
        #  description: Returns the list of players currently online
        #  required: false
        #4:
        #  type: boolean
        #  name: worlds
        #  description: Returns the worlds actively loaded
        #  required: false
        #5:
        #  type: boolean
        #  name: plugins
        #  description: Returns the currently loaded plugins
        #  required: false
        #6:
        #  type: boolean
        #  name: versions
        #  description: Returns the server's primary plugins and their current versions, or returns the version of all plugins when opting for plugins
        #  required: false
        #7:
        #  type: boolean
        #  name: chunks
        #  description: Returns the number of loaded chunks
        #  required: false
        #8:
        #  type: boolean
        #  name: tps
        #  description: Returns the tick per second as recorded by the server
        #  required: false
        #9:
        #  type: boolean
        #  name: scripts
        #  description: Returns the total number of each type of script
        #  required: false
        #10:
        #  type: boolean
        #  name: uptime
        #  description: Returns how long the server has been online for
        #  required: false

    - ~discordcommand id:a_bot create options:<[options]> name:status "Description:Shows the status of a server, or servers" group:626078288556851230

status_command_handler:
  type: world
  debug: false
  events:
    on discord slash command name:status:
      - define embed <discord_embed.with[color].as[<color[0,254,255]>]>
      - define description <list>

      - foreach <context.options> key:option as:input:
        - choose <[option]>:
          - case server:
            - if !<[input]>:
              - foreach next

          - if !<yaml[bungee_config].contains[servers.<[input]>]>:
            - define description "<[description].with_single[:warning: Opted for server <&qo>`<[input]>`<&qo> but this is not configured in the bungee's server listings.]>"

          - else if !<bungee.list_servers.contains[<[input]>]>:
            - define embed <[embed].add_inline_field[**<[option].to_titlecase>**].value[`Offline`]>

          - else:
              - ~bungeetag server:<[input].to_titlecase> <bungee.connected> save:request
              - if <entry[request].result> == 0:
                - define embed <[embed].add_inline_field[**<[option].to_titlecase>**].value[`Offline`]>
              - else:
                - define embed <[embed].add_inline_field[**<[option].to_titlecase>**].value[<entry[Data].result>]>

          # players argument template
          #- case players:
          #tag: "Online<&co> `(<server.online_players.size>)`<n>```md<n>- <server.online_players.parse[name].separated_by[<n>- ]>```"

      - define embed <[embed].with[description].as[<[description].separated_by[<n>]>]>

      - ~discordinteraction reply interaction:<context.interaction> <[embed]>

  legacy tags used:
    Players: Online<&co> `(<server.online_players.size>)`<n>```md<n>- <server.online_players.parse[name].separated_by[<n>- ]>```
    Worlds: <server.worlds.parse[name].comma_separated>
    Plugins: <server.list_plugins.parse_tag[<[Parse_Value].name><&co> `<[Parse_Value].version>`].separated_by[<n>]>
    Version: Version<&co> `<server.version>`<n>Denizen Version: `<server.denizen_version>`
    Versions: Version<&co> `<server.version>`<n><server.list_plugins.parse_tag[<[Parse_Value].name><&co> `<[Parse_Value].version>`].separated_by[<n>]>
    Chunks: <server.worlds.parse_tag[<[Parse_Value].name><&co> `<[Parse_Value].loaded_chunks.size>`].separated_by[<n>]>
    TPS: <server.recent_tps.parse[round_down_to_precision[0.001]].comma_separated>
    Scripts: Total Scripts<&co> `(<server.scripts.size>)`<n>Yaml Files<&co> `(<yaml.list.size>)`<n><server.scripts.parse[data_key[type]].deduplicate.parse_tag[<[Parse_Value].to_titlecase> Scripts<&co> `(<server.scripts.filter[data_key[type].is[==].to[<[Parse_Value]>]].size>)`].separated_by[<n>]>
    Uptime: Real<&co> `<server.real_time_since_start.formatted>`<n>Delta<&co> `<server.delta_time_since_start.formatted>`
