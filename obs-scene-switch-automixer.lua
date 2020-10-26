obs = obslua

local _pprint = require('vendor.pprint')
function pprint(obj)
    _pprint.pformat(obj, nil, print)
end

-- From https://stackoverflow.com/a/19266578
function sortedKeys(query, sortFunction)
    local keys, len = {}, 0
    for k,_ in pairs(query) do
        len = len + 1
        keys[len] = k
    end
    table.sort(keys, sortFunction)
    return keys
end

function dumpSortedAttrs(obj, label)
    print("### Dumping " .. label)
    for _, key in pairs(sortedKeys(obj)) do
        print(label .. ":  " .. type(obj[key]) .. ": " .. key .. " = " .. tostring(obj[key]))
    end
end

function map(list, func)
    new_list = {}
    for i, v in ipairs(list) do
        new_list[i] = func(v)
    end
    return new_list
end

function switchToScene(scene_name)
    local targetScene = obs.obs_get_source_by_name(scene_name)
    if targetScene then
        obs.obs_frontend_remove_event_callback(sceneChange)
        obs.obs_frontend_set_current_scene(targetScene)
        obs.obs_frontend_add_event_callback(sceneChange)
        obs.obs_source_release(targetScene)
    end
end

function setAudioState(src_name, volume, muted, relative)
    local audioSrc = obs.obs_get_source_by_name(src_name)
    local curVolume = obs.obs_source_get_volume(audioSrc)
    local newVolume = (relative and curVolume * volume) or volume
    obs.obs_source_set_muted(audioSrc, muted)
    obs.obs_source_set_volume(audioSrc, newVolume)
    obs.obs_source_release(audioSrc)

    return newVolume
end

bg_music_src = 'Mic/Aux'
main_mix_src = 'Desktop Audio'
scn_in = 'fadein'
scn_in_next = 'Main-Intro'
scn_out = 'fadeout'
scn_out_next = 'Main-Closing'

local transition_in_states = {'start', 'bg_music_fadeout', 'finish'}
local transition_out_states = {'start', 'main_mix_fadeout', 'finish'}

logging = true

function log (item)
    if logging then print (item) end
end

-- print("### Dumping global symbols (under _G table)")
-- pprint.pformat(_G, nil, print)
-- dumpSortedAttrs(_G, '_G')

-- print("### Dumping obslua symbols (under obslua table)")
-- pprint.pformat(obslua, nil, print)
-- dumpSortedAttrs(obslua, 'obslua')

-- dumpSortedAttrs(obs.obs_enum_scenes(), 'scenes')

-- local sources = obs.obs_enum_sources()
-- pprint(sources)
-- dumpSortedAttrs(sources, 'sources')
-- unversioned_sources = map(sources, obs.obs_source_get_unversioned_id)
-- dumpSortedAttrs(unversioned_sources, 'unversioned sources')
-- sourcesTypeData = map(sources, obs.obs_source_get_type_data)
-- dumpSortedAttrs(sourcesTypeData, 'source types list')
-- dumpSortedAttrs(map(sourcesTypeData, obs.obs_source_get_type), 'source types')
-- dumpSortedAttrs(map(sources, obs.obs_source_get_name), 'named sources')
-- dumpSortedAttrs(unversioned_sources, 'unversioned sources')
-- obs.source_list_release(sources)

function transition_in()
    obs.remove_current_callback()
    transition_state = transition_state or 'start'

    if transition_state == 'start' then
        switchToScene(scn_in_next)
        setAudioState(main_mix_src, 1, false, false)
        transition_state = 'bg_music_fadeout'
        obs.timer_add(transition_in, 50)
    elseif transition_state == 'bg_music_fadeout' then
        local newVolume = setAudioState(bg_music_src, 0.9275, false, true)
        if newVolume <= 0.001 then
            transition_state = 'finish'
        end
        obs.timer_add(transition_in, 50)
    elseif transition_state == 'finish' then
        setAudioState(bg_music_src, 1, true, false)
        transition_state = false
    end
end

function transition_out()
    obs.remove_current_callback()
    transition_state = transition_state or 'start'

    if transition_state == 'start' then
        setAudioState(bg_music_src, 1, false, false)
        transition_state = 'main_mix_fadeout'
        obs.timer_add(transition_out, 50)
    elseif transition_state == 'main_mix_fadeout' then
        local newVolume = setAudioState(main_mix_src, 0.9275, false, true)
        if newVolume <= 0.001 then
            transition_state = 'finish'
        end
        obs.timer_add(transition_out, 50)
    elseif transition_state == 'finish' then
        switchToScene(scn_out_next)
        setAudioState(main_mix_src, 1, true, false)
        transition_state = false
    end
end

function sceneChange(event)
    if event == obs.OBS_FRONTEND_EVENT_SCENE_CHANGED then
        local scene = obs.obs_frontend_get_current_scene()
        cur_scene = obs.obs_source_get_name(scene)
        log("At sceneChange, scene:  " .. cur_scene)

        if cur_scene == scn_in then
            obs.timer_add(transition_in, 500)
        end
        if cur_scene == scn_out then
            obs.timer_add(transition_out, 500)
        end

        obs.obs_source_release(scene)
    end
end

function script_load(settings)
    obs.obs_frontend_add_event_callback(sceneChange)
end

function script_description()
    return 'Soft switcher for audio sources\n' ..
           'by John Herreño 2020'
end
