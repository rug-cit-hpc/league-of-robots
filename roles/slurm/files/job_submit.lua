--[[

 This lua script:
 * assigns the right sub-QoS to each job, 
   based on a predefined table and assuming that each QoS will have a sub-QoS for short, medium and long jobs.
   The correct sub-QoS is chosen by comparing the time limit of the job to a given threshold.
 * Checks if the user submitting the job is associated to a Slurm account in the Slurm accounting database;
   If the relevant Slurm account or Slurm user or association does not yet exist in the DB,
   the missing pieces are automatically created.

 Note that this script should be 
  * named "job_submit.lua" and 
  * stored in the same directory as the SLURM configuration file, slurm.conf.
    the default location is /etc/slurm/slurm.conf
  * enabled in slurm.conf by adding:
    JobSubmitPlugins=lua
    
 When configured correctly the SLURM daemons will execute the following 2 functions automatically for each job:
  * slurm_job_submit on job submission.
  * slurm_job_modify when a job is modified.
  
 Documentation for the SLURM job submit Lua API is minimal. For available fields use the source @
    slurm-VERSION/src/plugins/job_submit/lua/

--]]

--
-- Only for debugging.
-- requires inspect.lua from https://github.com/kikito/inspect.lua
--
--local inspect = require 'inspect'

--
-- For a.o. coverting UIDs and GIDs to user- and groupnames.
--
local posix = require "posix"

--
-- Production QoS levels are divided in sub-levels for short, medium and long jobs as indicated by a suffix.
-- It is currently not possible to get a list of QoS levels from the SLURM job submit Lua API,
-- so if something changes in our QoS setup, we must change the hard-coded list of sub-QoS levels here.
--
QOS_TIME_LIMITS = {
    {6*60,    'short'},
    {1*24*60, 'medium'},
    {7*24*60, 'long'},
}

--
-- Disabled default walltime limit to force users to specify a walltime.
--
--DEFAULT_WALLTIME = '1'

function slurm_job_submit(job_desc, part_list, submit_uid)
    -- 
    -- Get details for the user who is trying to submit a job.
    --
    submit_user = posix.getpasswd(submit_uid)
    
    --
    -- Check if the job does have a time limit specified.
    -- For some reason (bug?), the nil value is passed as 4294967294.
    --
    if job_desc.time_limit == nil or job_desc.time_limit == 4294967294 then
        slurm.log_error("Walltime missing for job named %s from user %s (uid=%u). You must specify a walltime!", tostring(job_desc.name), tostring(submit_user.name), job_desc.user_id)
        slurm.log_user("Walltime missing for job named %s from user %s (uid=%u). You must specify a walltime!", tostring(job_desc.name), tostring(submit_user.name), job_desc.user_id)
    end
    
    --
    -- Select all partitions by default. 
    -- Which nodes in which partitions can be used by a job is determined by QoS or constraints a.k.a. features.
    --
    job_desc.partition = '' -- This will reset the partition list if the user specified any.
    local part_names = { }
    for name, part in pairs(part_list) do
        part_names[#part_names+1] = tostring(name)
    end
    job_desc.partition = table.concat(part_names, ',')
    slurm.log_debug("Assigned partition(s) %s to job named %s from user %s (uid=%u).", tostring(job_desc.partition), tostring(job_desc.name), tostring(submit_user.name), job_desc.user_id)
    
    --
    -- Check if we need a specific file system based on path to job's working directory, *.err file or *.out file.
    -- and adjust features/constraints accordingly. Note: these features may conflict with features/constraints requested by the user.
    --
    --slurm.log_debug("Job script = %s.", tostring(job_desc.script))
    --slurm.log_debug("Path to job *.out  = %s.", tostring(job_desc.std_out))
    --slurm.log_debug("Path to job *.err  = %s.", tostring(job_desc.std_err))
    --slurm.log_debug("Job's working dir  = %s.", tostring(job_desc.work_dir))
    local job_metadata = {job_desc.std_out, job_desc.std_err, job_desc.work_dir}
    for inx,job_metadata_value in ipairs(job_metadata) do
        if string.match(tostring(job_metadata_value), '^/home/') then
            slurm.log_error(
                "Job's working dir, *.err file or *.out file is located in a home dir, which is only designed for user preferences and not for massive parallel data crunching.\n" .. 
                "Use a /groups/${group}/tmp*/ file system instead.\n" ..
                "Rejecting job named %s from user %s (uid=%u).", tostring(job_desc.name), tostring(submit_user.name), job_desc.user_id)
            slurm.log_user(
                "Job's working dir, *.err file or *.out file is located in a home dir, which is only designed for user preferences and not for massive parallel data crunching.\n" .. 
                "Use a /groups/${group}/tmp*/ file system instead.\n" ..
                "Rejecting job named %s from user %s (uid=%u).", tostring(job_desc.name), tostring(submit_user.name), job_desc.user_id)
            return slurm.ERROR
        end
        local entitlement, group, lfs = string.match(tostring(job_metadata_value), '^/groups/([^/-]+)-([^/]+)/(tmp%d%d)/?')
        if lfs == nil then
            -- Temporary workaround for tmp02, which uses a symlink in /groups/..., that is resolved to the physical path by SLURM.
            entitlement, group, lfs = string.match(tostring(job_metadata_value), '^/target/gpfs2/groups/([^/-]+)-([^/]+)/(tmp%d%d)/?')
        end
        if entitlement ~= nil and group ~= nill and lfs ~= nil then
            slurm.log_debug("Found entitlement '%s' and LFS '%s' in job's metadata.", tostring(entitlement), tostring(lfs))
            if job_desc.features == nil or job_desc.features == '' then
                job_desc.features = entitlement .. '&' .. lfs
                slurm.log_debug("Job had no features yet; Assigned entitlement and LFS as first features: %s.", tostring(job_desc.features))
            else
                if not string.match(tostring(job_desc.features), entitlement) then
                    job_desc.features = job_desc.features .. '&' .. entitlement
                    slurm.log_debug("Appended entitlement %s to job's features.", tostring(entitlement))
                else
                    slurm.log_debug("Job's features already contained entitlement %s.", tostring(entitlement))
                end
                if not string.match(tostring(job_desc.features), lfs) then
                    job_desc.features = job_desc.features .. '&' .. lfs
                    slurm.log_debug("Appended LFS %s to job's features.", tostring(lfs))
                else
                    slurm.log_debug("Job's features already contained LFS %s.", tostring(lfs))
                end
            end
            slurm.log_info("Job's features now contains: %s.", tostring(job_desc.features))
        else
            slurm.log_error(
                 "Job's working dir, *.err file or *.out file is not located in /groups/${group}/tmp*/...\n" ..
                 "Found %s instead.\n" ..
                 "You may have specified the wrong file system or you have a typo in your job script.\n" ..
                 "Rejecting job named %s from user %s (uid=%u).", tostring(job_metadata_value), tostring(job_desc.name), tostring(submit_user.name), job_desc.user_id)
            slurm.log_user(
                 "Job's working dir, *.err file or *.out file is not located in /groups/${group}/tmp*/...\n" ..
                 "Found %s instead.\n" ..
                 "You may have specified the wrong file system or you have a typo in your job script.\n" ..
                 "Rejecting job named %s from user %s (uid=%u).", tostring(job_metadata_value), tostring(job_desc.name), tostring(submit_user.name), job_desc.user_id)
            return slurm.ERROR
        end
    end
    
    --
    -- Process final list of features:
    --  1. Check if features are specified in the correct format.
    --     A common mistake is to list multiple feature separated with a comma like in the node spec in slurm.conf,
    --     but when submitting jobs they must be separated with an & for logical AND (or with a | for logical OR).
    --  2. Check if we need a specific QoS based on features/constraints requested.
    --     Note: this may overrule the QoS requested by the user.
    --
    if job_desc.features ~= nil then
        local features = job_desc.features
        if string.match(features, ',') then
            slurm.log_error("Detected comma in list of requested features (%s) for job named %s from user %s (uid=%u). Multiple features must be joined with an ampersand (&) for logical AND.", tostring(features), tostring(job_desc.name), tostring(submit_user.name), job_desc.user_id)
            slurm.log_user("Detected comma in list of requested features (%s) for job named %s from user %s (uid=%u). Multiple features must be joined with an ampersand (&) for logical AND.", tostring(features), tostring(job_desc.name), tostring(submit_user.name), job_desc.user_id)
            return slurm.ERROR
        end
        slurm.log_info("features requested (%s) for job named %s from user %s (uid=%u). Will try to find suitable QoS...", tostring(features), tostring(job_desc.name), tostring(submit_user.name), job_desc.user_id)
        if string.match(features, 'dev') then
            job_desc.qos = 'dev'
        elseif string.match(features, 'ds') or string.match(features, 'prm') then
            job_desc.qos = 'ds'
        end
    end
      
    --
    -- Make sure we have a sanity checked base-QoS.
    --
    if job_desc.qos == nil then
        --
        -- Select default base-QoS if not set.
        --
        slurm.log_debug("No QoS level specified for job named %s from user %s (uid=%u). Will try to lookup default QoS...", tostring(job_desc.name), tostring(submit_user.name), job_desc.user_id)
        if job_desc.default_qos == nil then
            slurm.log_error("Failed to assign a default QoS for job named %s from user %s (uid=%u).", tostring(job_desc.name), tostring(submit_user.name), job_desc.user_id)
            slurm.log_user("Failed to assign a default QoS for job named %s from user %s (uid=%u).", tostring(job_desc.name), tostring(submit_user.name), job_desc.user_id)
            return slurm.ERROR
        else
            job_desc.qos = job_desc.default_qos
            slurm.log_debug("Found QoS %s for job named %s from user %s (uid=%u).", tostring(job_desc.qos), tostring(job_desc.name), tostring(submit_user.name), job_desc.user_id)
        end
    else
        --
        -- Sanity check: If the user accidentally specified a sub-QoS then reset the QoS by removing the sub-QoS suffix.
        --
        for index, sub_qos in ipairs(QOS_TIME_LIMITS) do
            local qos_suffix = sub_qos[2]
            slurm.log_debug("QoS %s before stripping sub-QoS suffix pattern %s.", tostring(job_desc.qos), tostring('-' .. qos_suffix .. '$'))
            job_desc.qos = string.gsub(job_desc.qos, '-' .. qos_suffix .. '$', '')
            slurm.log_debug("QoS %s after stripping sub-QoS suffix.", tostring(job_desc.qos), tostring(qos_suffix .. '$'))
        end
    end
    
    --
    -- Assign the right sub-QoS to the job.
    --
    local new_qos = false
    local qos_base = job_desc.qos
    for index, sub_qos in ipairs(QOS_TIME_LIMITS) do
        local qos_time_limit = sub_qos[1]
        local qos_suffix     = sub_qos[2]
        if job_desc.time_limit <= qos_time_limit then
            new_qos = qos_base .. '-' .. qos_suffix
            job_desc.qos = new_qos
            break
        end
    end
    
    --
    -- Sanity check if a valid sub-QOS has been found.
    --
    if not new_qos then
        slurm.log_error("Could not process job named %s from user %s (uid=%u) to assign a sub-QoS.", tostring(job_desc.name), tostring(submit_user.name), job_desc.user_id)
        slurm.log_user("Failed to assign a sub-QoS to the job named %s. Check the requested resources (cores, memory, walltime, etc.) as they do not fit any sub-QoS for QoS %s.", 
            tostring(job_desc.name), tostring(job_desc.qos)
        )
        return slurm.ERROR
    else
        slurm.log_info("Assigned QoS %s to job named %s from user %s (uid=%u).", new_qos, job_desc.name, tostring(submit_user.name), job_desc.user_id)
    end
    
    --
    -- Check if the user submitting the job is associated to a Slurm account in the Slurm accounting database and
    -- create the relevant Slurm account and/or Slurm user and/or association if it does not already exist.
    -- Skip this check for the root user.
    --
    if job_desc.user_id ~= 0 then
        --submit_user_primary_group = posix.getgroup(submit_user.gid).name
        --ensure_assoc_exists(submit_user.name, entitlement .. '-' .. group)
    end
    
    return slurm.SUCCESS
    
end

function slurm_job_modify(job_desc, job_rec, part_list, modify_uid)
--    if job_desc.comment == nil then
--        local comment = "***TEST_COMMENT***"
--        slurm.log_info("slurm_job_modify: for job %u from uid %u, setting default comment value: %s",
--                job_rec.job_id, modify_uid, comment)
--        job_desc.comment = comment
--    end
    return slurm.SUCCESS
end

function dump(o)
  if type(o) == 'table' then
    local s = '{ '
    for k,v in pairs(o) do
      if type(k) ~= 'number' then k = '"'..k..'"' end
      s = s .. '['..k..'] = ' .. dump(v) .. ','
    end
    return s .. '} '
  else
    return tostring(o)
  end
end

slurm.log_info("Initialized")
return slurm.SUCCESS
