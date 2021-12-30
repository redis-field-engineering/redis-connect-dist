## Supported Redis data structures

You can have one or more write stages in any Redis Connect job pipeline config. Here are the supported write stages, and it's usage examples within JobConfig.yml.

<details><summary>StringWriteStage</summary>
<p>

```yml
    StringWriteStage:
      handlerId: REDIS_STRING_WRITER
      connectionId: targetConnection
      metricsEnabled: false
      deleteOnKeyUpdate: true
      async: true
```

</p>
</details>

<details><summary>HashWriteStage</summary>
<p>

```yml
    HashWriteStage:
      handlerId: REDIS_HASH_WRITER
      connectionId: targetConnection
      metricsEnabled: false
      prependTableNameToKeys: true
      deleteOnKeyUpdate: true
      async: true
```

</p>
</details>

<details><summary>SetWriteStage</summary>
<p>

```yml
    Set1WriteStage:
      handlerId: REDIS_SET_WRITER
      connectionId: targetConnection
      metricsEnabled: false
      deleteOnKeyUpdate: true
      async: true
      delimiter: "|"
      keyPrefix: "empNumSet:"
      keyColumns:
        - empno
      valueColumns:
        - empno
    Set2WriteStage:
      handlerId: REDIS_SET_WRITER
      connectionId: targetConnection
      metricsEnabled: false
      deleteOnKeyUpdate: true
      async: true
      delimiter: "|"
      keyPrefix: "empNumSet:"
      keyColumns:
        - empno
      valueColumns:
        - fname
    Set3WriteStage:
      handlerId: REDIS_SET_WRITER
      connectionId: targetConnection
      metricsEnabled: false
      deleteOnKeyUpdate: true
      async: true
      delimiter: "|"
      keyPrefix: "empNumSet:"
      keyColumns:
        - empno
      valueColumns:
        - lname
```

</p>
</details>

<details><summary>SortedSetWriteStage</summary>
<p>

```yml
    SortedSetWriteStage:
      handlerId: REDIS_SORTEDSET_WRITER
      connectionId: targetConnection
      metricsEnabled: false
      deleteOnKeyUpdate: true
      async: true
      keyPrefix: "Z:DataSet"
      valueColumns:
        - empno
        - fname
        - lname
```

</p>
</details>

<details><summary>StreamWriteStage</summary>
<p>

```yml
    StreamWriteStage:
      handlerId: REDIS_STREAM_WRITER
      connectionId: targetConnection
      metricsEnabled: false
      deleteOnKeyUpdate: true
      async: true
```

</p>
</details>

<details><summary>JSONWriteStage</summary>
<p>

```yml
    JSONWriteStage:
      handlerId: REDIS_JSON_WRITER
      connectionId: targetConnection
      metricsEnabled: false
      prependTableNameToKeys: true
      deleteOnKeyUpdate: true
      async: true
```

</p>
</details>