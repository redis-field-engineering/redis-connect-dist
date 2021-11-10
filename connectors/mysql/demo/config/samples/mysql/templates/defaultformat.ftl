<#--
﻿<Operation type="U" table="EMP" schema="SCOTT"><TransactionInfo><RBA>13826</RBA><SeqNum>6</SeqNum><Position>00000000060000013826</Position><TxTime>2013-04-01 23:12:15.000052</TxTime><ReadTime>2013-04-01 16:12:20.276</ReadTime></TransactionInfo><Cols><Col name="empNo">7900</Col><Col name="salary">1000.00</Col></Cols></Operation>-->
<Operation type="${op.getType()}" table="${op.getTable()}" schema="${op.getSchema()}" rba="${op.getRba()}" seq="${op.getSeq()}" pos="${op.getPos()}" txTime="${op.getTxTime()}" readTime="${op.getReadTime()}">
    <#list op.getCols().getCol() as col>
        <#if col.before ??>
            <Col name="${col.getName()}" before="${col.getBefore()}">${col.getValue()}</Col>
        <#else>
            <Col name="${col.getName()}">${col.getValue()}</Col>
        </#if>
    </#list>
</Operation>