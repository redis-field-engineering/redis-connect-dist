<#macro compress_single_line><#local captured><#nested></#local>${captured?replace("^\\s+|\\s+$|\\n|\\r", "", "rm")}</#macro>
<@compress_single_line>
    <#if delete??>
        <#if op.type?matches('D','i')>
            <#list op.getCols().getCol()?filter(it -> it??) as col>
                ${col.name}:
                <#if col.before ??>${col.before}</#if>
                <#if col?has_next>,</#if>
            </#list>
        <#else>
            <#list op.getCols().getCol()?filter(it -> it??) as col>
                ${col.name}:
                <#if col.changed>
                    <#if col.before??>${col.before}</#if>
                <#else>
                    <#if col.value??>${col.value}</#if>
                </#if>
                <#if col?has_next>,</#if>
            </#list>
        </#if>
    <#else>
        <#list op.getCols().getCol()?filter(it -> it??) as col>
            ${col.name}:
            <#if col.value ??>${col.value}</#if>
            <#if col?has_next>,</#if>
        </#list>
    </#if>
</@compress_single_line>