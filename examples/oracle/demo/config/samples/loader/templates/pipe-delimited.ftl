<#list op.getCols().getCol() as col><#if col.value ??>${col.getValue()}|<#else>|</#if></#list>
