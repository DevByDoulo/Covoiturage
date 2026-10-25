<?xml version="1.0" encoding="UTF-8"?>
<?PowerDesigner AppLocale="UTF16" ID="{EAB39E9D-AF5C-41CD-956B-4963F453EB96}" Label="" LastModificationDate="1792197166" Name="Diagramme de classe PFF - corrige" Objects="462" Symbols="41" Target="Java" TargetLink="Reference" Type="{18112060-1A4B-11D1-83D9-444553540000}" signature="CLD_OBJECT_MODEL" version="16.6.10.6261"?>
<!-- Veuillez ne pas modifier ce fichier -->

<Model xmlns:a="attribute" xmlns:c="collection" xmlns:o="object">

<o:RootObject Id="o1">
<a:SessionID>00000000-0000-0000-0000-000000000000</a:SessionID>
<c:Children>
<o:Model Id="o2">
<a:ObjectID>EAB39E9D-AF5C-41CD-956B-4963F453EB96</a:ObjectID>
<a:Name>Diagramme de classe PFF - corrige</a:Name>
<a:Code>Diagramme_de_classe_PFF_corrige</a:Code>
<a:CreationDate>1791417238</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792197138</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:PackageOptionsText>[FolderOptions]

[FolderOptions\Class Diagram Objects]
GenerationCheckModel=Yes
GenerationPath=
GenerationOptions=
GenerationTasks=
GenerationTargets=
GenerationSelections=</a:PackageOptionsText>
<a:ModelOptionsText>[ModelOptions]

[ModelOptions\Cld]
CaseSensitive=Yes
DisplayName=Yes
EnableTrans=Yes
UseTerm=No
EnableRequirements=No
EnableFullShortcut=Yes
SynchroCode=Yes
ShowClss=No
DeftAttr=int
DeftMthd=int
DeftParm=int
DeftCont=java.util.Collection
DomnDttp=Yes
DomnChck=No
DomnRule=No
SupportDelay=No
PreviewEditable=Yes
AutoRealize=No
DttpFullName=Yes
DeftClssAttrVisi=private
VBNetPreprocessingSymbols=
CSharpPreprocessingSymbols=

[ModelOptions\Cld\NamingOptionsTemplates]

[ModelOptions\Cld\ClssNamingOptions]

[ModelOptions\Cld\ClssNamingOptions\CLDPCKG]

[ModelOptions\Cld\ClssNamingOptions\CLDPCKG\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,,,firstLowerWord)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\CLDPCKG\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\CLDDOMN]

[ModelOptions\Cld\ClssNamingOptions\CLDDOMN\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\CLDDOMN\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\CLDCLASS]

[ModelOptions\Cld\ClssNamingOptions\CLDCLASS\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,,,FirstUpperChar)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\CLDCLASS\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\CLDINTF]

[ModelOptions\Cld\ClssNamingOptions\CLDINTF\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,,,FirstUpperChar)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\CLDINTF\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\UCDACTR]

[ModelOptions\Cld\ClssNamingOptions\UCDACTR\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\UCDACTR\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\UCDUCAS]

[ModelOptions\Cld\ClssNamingOptions\UCDUCAS\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\UCDUCAS\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\SQDOBJT]

[ModelOptions\Cld\ClssNamingOptions\SQDOBJT\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\SQDOBJT\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\SQDMSSG]

[ModelOptions\Cld\ClssNamingOptions\SQDMSSG\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\SQDMSSG\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\CPDCOMP]

[ModelOptions\Cld\ClssNamingOptions\CPDCOMP\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,,,FirstUpperChar)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\CPDCOMP\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\CLDATTR]

[ModelOptions\Cld\ClssNamingOptions\CLDATTR\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,,,firstLowerWord)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\CLDATTR\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\CLDMETHOD]

[ModelOptions\Cld\ClssNamingOptions\CLDMETHOD\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,,,firstLowerWord)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\CLDMETHOD\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\CLDPARM]

[ModelOptions\Cld\ClssNamingOptions\CLDPARM\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,,,firstLowerWord)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\CLDPARM\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\OOMPORT]

[ModelOptions\Cld\ClssNamingOptions\OOMPORT\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\OOMPORT\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\OOMPART]

[ModelOptions\Cld\ClssNamingOptions\OOMPART\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\OOMPART\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\CLDASSC]

[ModelOptions\Cld\ClssNamingOptions\CLDASSC\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,,,firstLowerWord)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\CLDASSC\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\UCDASSC]

[ModelOptions\Cld\ClssNamingOptions\UCDASSC\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\UCDASSC\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\GNRLLINK]

[ModelOptions\Cld\ClssNamingOptions\GNRLLINK\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\GNRLLINK\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\RQLINK]

[ModelOptions\Cld\ClssNamingOptions\RQLINK\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\RQLINK\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\RLZSLINK]

[ModelOptions\Cld\ClssNamingOptions\RLZSLINK\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\RLZSLINK\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\DEPDLINK]

[ModelOptions\Cld\ClssNamingOptions\DEPDLINK\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\DEPDLINK\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\OOMACTV]

[ModelOptions\Cld\ClssNamingOptions\OOMACTV\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\OOMACTV\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\ACDOBST]

[ModelOptions\Cld\ClssNamingOptions\ACDOBST\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\ACDOBST\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\STAT]

[ModelOptions\Cld\ClssNamingOptions\STAT\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\STAT\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\DPDNODE]

[ModelOptions\Cld\ClssNamingOptions\DPDNODE\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\DPDNODE\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\DPDCMPI]

[ModelOptions\Cld\ClssNamingOptions\DPDCMPI\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\DPDCMPI\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\DPDASSC]

[ModelOptions\Cld\ClssNamingOptions\DPDASSC\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\DPDASSC\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\OOMVAR]

[ModelOptions\Cld\ClssNamingOptions\OOMVAR\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\OOMVAR\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\FILO]

[ModelOptions\Cld\ClssNamingOptions\FILO\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=&quot;\/:*?&lt;&gt;|&quot;
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\FILO\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_. &quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\FRMEOBJ]

[ModelOptions\Cld\ClssNamingOptions\FRMEOBJ\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\FRMEOBJ\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\FRMELNK]

[ModelOptions\Cld\ClssNamingOptions\FRMELNK\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\FRMELNK\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\AREA]

[ModelOptions\Cld\ClssNamingOptions\AREA\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\AREA\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\DefaultClass]

[ModelOptions\Cld\ClssNamingOptions\DefaultClass\Name]
Template=
MaxLen=254
Case=M
ValidChar=
InvldChar=
AllValid=Yes
NoAccent=No
DefaultChar=_
Script=.convert_name(%Name%,&quot;_&quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Cld\ClssNamingOptions\DefaultClass\Code]
Template=
MaxLen=254
Case=M
ValidChar=&#39;a&#39;-&#39;z&#39;,&#39;A&#39;-&#39;Z&#39;,&#39;0&#39;-&#39;9&#39;,&quot;_&quot;
InvldChar=&quot; &#39;(.)+=*/&quot;
AllValid=Yes
NoAccent=Yes
DefaultChar=_
Script=.convert_code(%Code%,&quot; &quot;)
ConvTable=
ConvTablePath=%_HOME%\Resource Files\Conversion Tables

[ModelOptions\Generate]

[ModelOptions\Generate\Xsm]
GenRootElement=Yes
GenComplexType=No
GenAttribute=Yes
CheckModel=Yes
SaveLinks=Yes
ORMapping=No
NameToCode=No

[ModelOptions\Generate\Cdm]
CheckModel=Yes
SaveLinks=Yes
NameToCode=No
Notation=2

[ModelOptions\Generate\Pdm]
CheckModel=Yes
SaveLinks=Yes
ORMapping=No
NameToCode=No
BuildTrgr=No
TablePrefix=
IndxPKName=%TABLE%_PK
IndxAKName=%TABLE%_AK
IndxFKName=%REFR%_FK
IndxThreshold=
ColnFKName=%TABLE%_PK
ColnFKNameUse=No</a:ModelOptionsText>
<a:RepositoryFilename>C:\PFF_Covoiturage\CoVoiturage_Diagramme_Classe.moo</a:RepositoryFilename>
<c:ObjectLanguage>
<o:Shortcut Id="o3">
<a:ObjectID>2CB7C86F-5300-4FB2-B0AB-17FF458A9B4F</a:ObjectID>
<a:Name>Java</a:Name>
<a:Code>Java</a:Code>
<a:CreationDate>1791417237</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791417237</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:TargetStereotype/>
<a:TargetID>0DEDDB90-46E2-45A0-886E-411709DA0DC9</a:TargetID>
<a:TargetClassID>1811206C-1A4B-11D1-83D9-444553540000</a:TargetClassID>
</o:Shortcut>
</c:ObjectLanguage>
<c:ExtendedModelDefinitions>
<o:Shortcut Id="o4">
<a:ObjectID>0D3E8F32-42C5-41DB-95A4-BD6F40253160</a:ObjectID>
<a:Name>WSDL for Java</a:Name>
<a:Code>WSDLJava</a:Code>
<a:CreationDate>1791417238</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791417238</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:TargetStereotype/>
<a:TargetID>C8F5F7B2-CF9D-4E98-8301-959BB6E86C8A</a:TargetID>
<a:TargetClassID>186C8AC3-D3DC-11D3-881C-00508B03C75C</a:TargetClassID>
</o:Shortcut>
</c:ExtendedModelDefinitions>
<c:ClassDiagrams>
<o:ClassDiagram Id="o5">
<a:ObjectID>0E8B5AFD-8545-4895-9748-9026315E5DC0</a:ObjectID>
<a:Name>Diagramme de classe PFF</a:Name>
<a:Code>Diagramme_de_classe_PFF</a:Code>
<a:CreationDate>1791417238</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792197138</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DisplayPreferences>[DisplayPreferences]

[DisplayPreferences\CLD]

[DisplayPreferences\General]
Adjust to text=Yes
Snap Grid=No
Constrain Labels=Yes
Display Grid=No
Show Page Delimiter=Yes
Show Links intersections=Yes
Activate automatic link routing=Yes
Grid size=0
Graphic unit=2
Window color=255, 255, 255
Background image=
Background mode=8
Watermark image=
Watermark mode=8
Show watermark on screen=No
Gradient mode=0
Gradient end color=255, 255, 255
Show Swimlane=No
SwimlaneVert=Yes
TreeVert=No
CompDark=0

[DisplayPreferences\Object]
Show Icon=No
Mode=0
Trunc Length=80
Word Length=80
Word Text=!&quot;&quot;#$%&amp;&#39;()*+,-./:;&lt;=&gt;?@[\]^_`{|}~
Shortcut IntIcon=Yes
Shortcut IntLoct=Yes
Shortcut IntFullPath=No
Shortcut IntLastPackage=Yes
Shortcut ExtIcon=Yes
Shortcut ExtLoct=No
Shortcut ExtFullPath=No
Shortcut ExtLastPackage=Yes
Shortcut ExtIncludeModl=Yes
Area.IconPicture=Yes
Area.Stereotype=Yes
Area.Comment=No
Area.TextStyle=No
Area.SubSymbols=Yes
Area_SymbolLayout=&lt;Form&gt;[CRLF] &lt;StandardAttribute Name=&quot;Icône&quot; Attribute=&quot;IconPicture&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Alignment=&quot;CNTR&quot; Caption=&quot;&quot; Mandatory=&quot;Yes&quot; /&gt;[CRLF] &lt;StandardAttribute Name=&quot;Stéréotype&quot; Attribute=&quot;Stereotype&quot; Prefix=&quot;&amp;lt;&amp;lt;&quot; Suffix=&quot;&amp;gt;&amp;gt;&quot; Alignment=&quot;CNTR&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;StandardAttribute Name=&quot;Nom de zone&quot; Attribute=&quot;DisplayName&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Alignment=&quot;CNTR&quot; Caption=&quot;&quot; Mandatory=&quot;Yes&quot; /&gt;[CRLF] &lt;Separator Name=&quot;Séparateur&quot; /&gt;[CRLF] &lt;StandardAttribute Name=&quot;Commentaire&quot; Attribute=&quot;Comment&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Alignment=&quot;LEFT&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;StandardAttribute Name=&quot;Forcer l&amp;#39;alignement en haut&quot; Attribute=&quot;TextStyle&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Alignment=&quot;CNTR&quot; Caption=&quot;&quot; Mandatory=&quot;Yes&quot; /&gt;[CRLF]&lt;/Form&gt;
EObjShowStrn=Yes
ExtendedObject.Comment=No
ExtendedObject.IconPicture=No
ExtendedObject.TextStyle=No
ExtendedObject_SymbolLayout=
ELnkShowStrn=Yes
ELnkShowName=Yes
ExtendedLink_SymbolLayout=
ExtDpdShowStrn=Yes
ExtendedDependency_SymbolLayout=&lt;Form&gt;[CRLF] &lt;Form Name=&quot;Centre&quot; &gt;[CRLF]  &lt;StandardAttribute Name=&quot;Stéréotype&quot; Attribute=&quot;Stereotype&quot; Prefix=&quot;&amp;lt;&amp;lt;&quot; Suffix=&quot;&amp;gt;&amp;gt;&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;/Form&gt;[CRLF] &lt;Form Name=&quot;Source&quot; &gt;[CRLF] &lt;/Form&gt;[CRLF] &lt;Form Name=&quot;Destination&quot; &gt;[CRLF] &lt;/Form&gt;[CRLF]&lt;/Form&gt;
FileObject.Stereotype=No
FileObject.DisplayName=Yes
FileObject.LocationOrName=No
FileObject.IconPicture=No
FileObject.TextStyle=No
FileObject.IconMode=Yes
FileObject_SymbolLayout=
Package.Stereotype=Yes
Package.Comment=No
Package.IconPicture=No
Package.TextStyle=No
Package_SymbolLayout=
Display Model Version=Yes
Generalization.DisplayedStereotype=Yes
Generalization.DisplayName=No
Generalization.DisplayedRules=Yes
Generalization_SymbolLayout=&lt;Form&gt;[CRLF] &lt;Form Name=&quot;Centre&quot; &gt;[CRLF]  &lt;StandardAttribute Name=&quot;Stéréotype&quot; Attribute=&quot;DisplayedStereotype&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF]  &lt;StandardAttribute Name=&quot;Nom&quot; Attribute=&quot;DisplayName&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF]  &lt;StandardAttribute Name=&quot;Contrainte&quot; Attribute=&quot;DisplayedRules&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;/Form&gt;[CRLF] &lt;Form Name=&quot;Source&quot; &gt;[CRLF] &lt;/Form&gt;[CRLF] &lt;Form Name=&quot;Destination&quot; &gt;[CRLF] &lt;/Form&gt;[CRLF]&lt;/Form&gt;
Realization.DisplayedStereotype=Yes
Realization.DisplayName=No
Realization.DisplayedRules=Yes
Realization_SymbolLayout=
Dependency.DisplayedStereotype=Yes
Dependency.DisplayName=No
Dependency.DisplayedRules=Yes
Dependency_SymbolLayout=&lt;Form&gt;[CRLF] &lt;Form Name=&quot;Centre&quot; &gt;[CRLF]  &lt;StandardAttribute Name=&quot;Stéréotype&quot; Attribute=&quot;DisplayedStereotype&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF]  &lt;StandardAttribute Name=&quot;Nom&quot; Attribute=&quot;DisplayName&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF]  &lt;StandardAttribute Name=&quot;Contrainte&quot; Attribute=&quot;DisplayedRules&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;/Form&gt;[CRLF] &lt;Form Name=&quot;Source&quot; &gt;[CRLF] &lt;/Form&gt;[CRLF] &lt;Form Name=&quot;Destination&quot; &gt;[CRLF] &lt;/Form&gt;[CRLF]&lt;/Form&gt;
Class.Stereotype=Yes
Class.Constraint=Yes
Class.Attributes=Yes
Class.Attributes._Columns=DisplayVisibilityMarker Stereotype DataType InitialValue
Class.Attributes._Limit=-3
Class.Operations=Yes
Class.Operations._Columns=DisplayVisibilityMarker Stereotype SignatureWithParameters ReturnType
Class.Operations._Limit=-3
Class.InnerClassifiers=Yes
Class.Comment=No
Class.IconPicture=No
Class.TextStyle=No
Class_SymbolLayout=&lt;Form&gt;[CRLF] &lt;StandardAttribute Name=&quot;Stéréotype&quot; Attribute=&quot;Stereotype&quot; Prefix=&quot;&amp;lt;&amp;lt;&quot; Suffix=&quot;&amp;gt;&amp;gt;&quot; Alignment=&quot;CNTR&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;StandardAttribute Name=&quot;Nom de classe&quot; Attribute=&quot;DisplayedQualifiedName&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Alignment=&quot;CNTR&quot; Caption=&quot;&quot; Mandatory=&quot;Yes&quot; /&gt;[CRLF] &lt;StandardAttribute Name=&quot;Contrainte&quot; Attribute=&quot;Constraint&quot; Prefix=&quot;{&quot; Suffix=&quot;}&quot; Alignment=&quot;RGHT&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;Separator Name=&quot;Séparateur&quot; /&gt;[CRLF] &lt;StandardCollection Name=&quot;Attributs&quot; Collection=&quot;Attributes&quot; Columns=&quot;DisplayVisibilityMarker No\r\nDisplayVisibilityKeyword No\r\nDisplayVisibilityIcon No\r\nStereotype No\r\nDisplayName Yes\r\nDataType No\r\nDomain No\r\nInitialValue No&quot; HasLimit=&quot;Yes&quot; HideEmpty=&quot;No&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;StandardCollection Name=&quot;Opérations&quot; Collection=&quot;Operations&quot; Columns=&quot;DisplayVisibilityMarker No\r\nDisplayVisibilityKeyword No\r\nDisplayVisibilityIcon No\r\nStereotype No\r\nSignatureWithoutParameters No\r\nSignatureWithParameters No\r\nReturnType No&quot; HasLimit=&quot;Yes&quot; HideEmpty=&quot;No&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;StandardCollection Name=&quot;Classificateurs internes&quot; Collection=&quot;InnerClassifiers&quot; Columns=&quot;DisplayInnerIcon Yes\r\nDisplayNameGeneric Yes&quot; HasLimit=&quot;No&quot; HideEmpty=&quot;Yes&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;StandardAttribute Name=&quot;Commentaire&quot; Attribute=&quot;Comment&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Alignment=&quot;LEFT&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;StandardAttribute Name=&quot;Icône&quot; Attribute=&quot;IconPicture&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Alignment=&quot;CNTR&quot; Caption=&quot;&quot; Mandatory=&quot;Yes&quot; /&gt;[CRLF] &lt;StandardAttribute Name=&quot;Forcer l&amp;#39;alignement en haut&quot; Attribute=&quot;TextStyle&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Alignment=&quot;CNTR&quot; Caption=&quot;&quot; Mandatory=&quot;Yes&quot; /&gt;[CRLF]&lt;/Form&gt;
Interface.Stereotype=Yes
Interface.Constraint=Yes
Interface.Attributes=Yes
Interface.Attributes._Columns=DisplayVisibilityMarker Stereotype DataType InitialValue
Interface.Attributes._Limit=-3
Interface.Operations=Yes
Interface.Operations._Columns=DisplayVisibilityMarker Stereotype SignatureWithParameters ReturnType
Interface.Operations._Limit=-3
Interface.InnerClassifiers=Yes
Interface.Comment=No
Interface.IconPicture=No
Interface.TextStyle=No
Interface_SymbolLayout=&lt;Form&gt;[CRLF] &lt;StandardAttribute Name=&quot;Stéréotype&quot; Attribute=&quot;Stereotype&quot; Prefix=&quot;&amp;lt;&amp;lt;&quot; Suffix=&quot;&amp;gt;&amp;gt;&quot; Alignment=&quot;CNTR&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;StandardAttribute Name=&quot;Nom d&amp;#39;interface&quot; Attribute=&quot;DisplayedQualifiedName&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Alignment=&quot;CNTR&quot; Caption=&quot;&quot; Mandatory=&quot;Yes&quot; /&gt;[CRLF] &lt;StandardAttribute Name=&quot;Contrainte&quot; Attribute=&quot;Constraint&quot; Prefix=&quot;{&quot; Suffix=&quot;}&quot; Alignment=&quot;RGHT&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;Separator Name=&quot;Séparateur&quot; /&gt;[CRLF] &lt;StandardCollection Name=&quot;Attributs&quot; Collection=&quot;Attributes&quot; Columns=&quot;DisplayVisibilityMarker No\r\nDisplayVisibilityKeyword No\r\nDisplayVisibilityIcon No\r\nStereotype No\r\nDisplayName Yes\r\nDataType No\r\nDomain No\r\nInitialValue No&quot; HasLimit=&quot;Yes&quot; HideEmpty=&quot;No&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;StandardCollection Name=&quot;Opérations&quot; Collection=&quot;Operations&quot; Columns=&quot;DisplayVisibilityMarker No\r\nDisplayVisibilityKeyword No\r\nDisplayVisibilityIcon No\r\nStereotype No\r\nSignatureWithoutParameters No\r\nSignatureWithParameters No\r\nReturnType No&quot; HasLimit=&quot;Yes&quot; HideEmpty=&quot;No&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;StandardCollection Name=&quot;Classificateurs internes&quot; Collection=&quot;InnerClassifiers&quot; Columns=&quot;DisplayInnerIcon Yes\r\nDisplayNameGeneric Yes&quot; HasLimit=&quot;No&quot; HideEmpty=&quot;Yes&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;StandardAttribute Name=&quot;Commentaire&quot; Attribute=&quot;Comment&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Alignment=&quot;LEFT&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;StandardAttribute Name=&quot;Icône&quot; Attribute=&quot;IconPicture&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Alignment=&quot;CNTR&quot; Caption=&quot;&quot; Mandatory=&quot;Yes&quot; /&gt;[CRLF] &lt;StandardAttribute Name=&quot;Forcer l&amp;#39;alignement en haut&quot; Attribute=&quot;TextStyle&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Alignment=&quot;CNTR&quot; Caption=&quot;&quot; Mandatory=&quot;Yes&quot; /&gt;[CRLF]&lt;/Form&gt;
Port.IconPicture=No
Port.TextStyle=No
Port_SymbolLayout=
Association.RoleAMultiplicity=Yes
Association.RoleAName=Yes
Association.RoleAOrdering=Yes
Association.DisplayedStereotype=No
Association.DisplayName=No
Association.DisplayedRules=Yes
Association.RoleBMultiplicity=Yes
Association.RoleBName=Yes
Association.RoleBOrdering=Yes
Association.RoleMultiplicitySymbol=No
Association_SymbolLayout=&lt;Form&gt;[CRLF] &lt;Form Name=&quot;Source&quot; &gt;[CRLF]  &lt;StandardAttribute Name=&quot;Multiplicité A&quot; Attribute=&quot;RoleAMultiplicity&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF]  &lt;StandardAttribute Name=&quot;Rôle A&quot; Attribute=&quot;RoleAName&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF]  &lt;StandardAttribute Name=&quot;Ordre A&quot; Attribute=&quot;RoleAOrdering&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;/Form&gt;[CRLF] &lt;Form Name=&quot;Centre&quot; &gt;[CRLF]  &lt;StandardAttribute Name=&quot;Stéréotype&quot; Attribute=&quot;DisplayedStereotype&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF]  &lt;StandardAttribute Name=&quot;Nom&quot; Attribute=&quot;DisplayName&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF]  &lt;StandardAttribute Name=&quot;Contrainte&quot; Attribute=&quot;DisplayedRules&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;/Form&gt;[CRLF] &lt;Form Name=&quot;Destination&quot; &gt;[CRLF]  &lt;StandardAttribute Name=&quot;Multiplicité B&quot; Attribute=&quot;RoleBMultiplicity&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF]  &lt;StandardAttribute Name=&quot;Rôle B&quot; Attribute=&quot;RoleBName&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF]  &lt;StandardAttribute Name=&quot;Ordre B&quot; Attribute=&quot;RoleBOrdering&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;/Form&gt;[CRLF]&lt;/Form&gt;
RequireLink.DisplayedStereotype=Yes
RequireLink.DisplayName=No
RequireLink.DisplayedRules=Yes
RequireLink_SymbolLayout=&lt;Form&gt;[CRLF] &lt;Form Name=&quot;Centre&quot; &gt;[CRLF]  &lt;StandardAttribute Name=&quot;Stéréotype&quot; Attribute=&quot;DisplayedStereotype&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF]  &lt;StandardAttribute Name=&quot;Nom&quot; Attribute=&quot;DisplayName&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF]  &lt;StandardAttribute Name=&quot;Contrainte&quot; Attribute=&quot;DisplayedRules&quot; Prefix=&quot;&quot; Suffix=&quot;&quot; Caption=&quot;&quot; Mandatory=&quot;No&quot; /&gt;[CRLF] &lt;/Form&gt;[CRLF] &lt;Form Name=&quot;Source&quot; &gt;[CRLF] &lt;/Form&gt;[CRLF] &lt;Form Name=&quot;Destination&quot; &gt;[CRLF] &lt;/Form&gt;[CRLF]&lt;/Form&gt;
PortShowName=Yes
PortShowType=No
PortShowMult=No

[DisplayPreferences\Symbol]

[DisplayPreferences\Symbol\AREA]
STRNFont=Arial,8,N
STRNFont color=0 0 0
DISPNAMEFont=Arial,8,N
DISPNAMEFont color=0 0 0
LABLFont=Arial,8,N
LABLFont color=0 0 0
AutoAdjustToText=Yes
Keep aspect=No
Keep center=No
Keep size=No
Width=9600
Height=8000
Brush color=253 249 234
Fill Color=Yes
Brush style=6
Brush bitmap mode=12
Brush gradient mode=16
Brush gradient color=245 230 173
Brush background image=
Custom shape=
Custom text mode=0
Pen=1 0 121 98 6
Shadow color=192 192 192
Shadow=0

[DisplayPreferences\Symbol\FRMEOBJ]
STRNFont=Arial,8,N
STRNFont color=0, 0, 0
DISPNAMEFont=Arial,8,N
DISPNAMEFont color=0, 0, 0
LABLFont=Arial,8,N
LABLFont color=0, 0, 0
AutoAdjustToText=Yes
Keep aspect=No
Keep center=No
Keep size=No
Width=6000
Height=2000
Brush color=255 255 255
Fill Color=Yes
Brush style=6
Brush bitmap mode=12
Brush gradient mode=64
Brush gradient color=192 192 192
Brush background image=
Custom shape=
Custom text mode=0
Pen=1 0 255 128 128
Shadow color=192 192 192
Shadow=0

[DisplayPreferences\Symbol\FRMELNK]
CENTERFont=Arial,8,N
CENTERFont color=0, 0, 0
Line style=2
Source Arrow=24
Center Arrow=24
Target Arrow=7
AutoAdjustToText=Yes
Keep aspect=No
Keep center=No
Keep size=No
Brush color=255 255 255
Fill Color=Yes
Brush style=1
Brush bitmap mode=12
Brush gradient mode=0
Brush gradient color=118 118 118
Brush background image=
Custom shape=
Custom text mode=0
Pen=1 0 128 128 255
Shadow color=192 192 192
Shadow=0

[DisplayPreferences\Symbol\USRDEPD]
CENTERFont=Arial,8,N
CENTERFont color=0 0 0
Line style=2
Source Arrow=24
Center Arrow=24
Target Arrow=7
AutoAdjustToText=Yes
Keep aspect=No
Keep center=No
Keep size=No
Brush color=255 255 255
Fill Color=Yes
Brush style=1
Brush bitmap mode=12
Brush gradient mode=0
Brush gradient color=118 118 118
Brush background image=
Custom shape=
Custom text mode=0
Pen=2 0 128 0 64
Shadow color=192 192 192
Shadow=0

[DisplayPreferences\Symbol\FILO]
OBJSTRNFont=Arial,8,N
OBJSTRNFont color=0 0 0
DISPNAMEFont=Arial,8,N
DISPNAMEFont color=0 0 0
LCNMFont=Arial,8,N
LCNMFont color=0 0 0
AutoAdjustToText=Yes
Keep aspect=Yes
Keep center=Yes
Keep size=No
Width=2400
Height=2400
Brush color=255 255 255
Fill Color=No
Brush style=1
Brush bitmap mode=12
Brush gradient mode=0
Brush gradient color=118 118 118
Brush background image=
Custom shape=
Custom text mode=0
Pen=1 0 0 0 255
Shadow color=192 192 192
Shadow=-1

[DisplayPreferences\Symbol\CLDPCKG]
STRNFont=Arial,8,N
STRNFont color=0 0 0
DISPNAMEFont=Arial,8,N
DISPNAMEFont color=0 0 0
LABLFont=Arial,8,N
LABLFont color=0 0 0
AutoAdjustToText=Yes
Keep aspect=No
Keep center=No
Keep size=No
Width=4800
Height=3600
Brush color=255 255 192
Fill Color=Yes
Brush style=6
Brush bitmap mode=12
Brush gradient mode=65
Brush gradient color=255 255 255
Brush background image=
Custom shape=
Custom text mode=0
Pen=1 0 178 178 178
Shadow color=192 192 192
Shadow=0

[DisplayPreferences\Symbol\GNRLLINK]
CENTERFont=Arial,8,N
CENTERFont color=0 0 0
Line style=2
Source Arrow=24
Center Arrow=24
Target Arrow=6
AutoAdjustToText=Yes
Keep aspect=No
Keep center=No
Keep size=No
Brush color=255 255 255
Fill Color=Yes
Brush style=1
Brush bitmap mode=12
Brush gradient mode=0
Brush gradient color=118 118 118
Brush background image=
Custom shape=
Custom text mode=0
Pen=1 0 128 0 64
Shadow color=192 192 192
Shadow=0

[DisplayPreferences\Symbol\RLZSLINK]
CENTERFont=Arial,8,N
CENTERFont color=0 0 0
Line style=2
Source Arrow=24
Center Arrow=24
Target Arrow=6
AutoAdjustToText=Yes
Keep aspect=No
Keep center=No
Keep size=No
Brush color=255 255 255
Fill Color=Yes
Brush style=1
Brush bitmap mode=12
Brush gradient mode=0
Brush gradient color=118 118 118
Brush background image=
Custom shape=
Custom text mode=0
Pen=3 0 128 0 64
Shadow color=192 192 192
Shadow=0

[DisplayPreferences\Symbol\DEPDLINK]
CENTERFont=Arial,8,N
CENTERFont color=0 0 0
Line style=2
Source Arrow=24
Center Arrow=24
Target Arrow=7
AutoAdjustToText=Yes
Keep aspect=No
Keep center=No
Keep size=No
Brush color=255 255 255
Fill Color=Yes
Brush style=1
Brush bitmap mode=12
Brush gradient mode=0
Brush gradient color=118 118 118
Brush background image=
Custom shape=
Custom text mode=0
Pen=2 0 128 0 64
Shadow color=192 192 192
Shadow=0

[DisplayPreferences\Symbol\CLDCLASS]
STRNFont=Arial,8,N
STRNFont color=0 0 0
QDNMFont=Arial,8,N
QDNMFont color=0 0 0
CNTRFont=Arial,8,N
CNTRFont color=0 0 0
AttributesFont=Arial,8,N
AttributesFont color=0 0 0
ClassPrimaryAttributeFont=Arial,8,U
ClassPrimaryAttributeFont color=0 0 0
OperationsFont=Arial,8,N
OperationsFont color=0 0 0
InnerClassifiersFont=Arial,8,N
InnerClassifiersFont color=0 0 0
LABLFont=Arial,8,N
LABLFont color=0 0 0
AutoAdjustToText=Yes
Keep aspect=No
Keep center=No
Keep size=No
Width=4800
Height=3600
Brush color=233 202 131
Fill Color=Yes
Brush style=6
Brush bitmap mode=12
Brush gradient mode=65
Brush gradient color=255 255 255
Brush background image=
Custom shape=
Custom text mode=0
Pen=1 0 128 0 0
Shadow color=192 192 192
Shadow=0

[DisplayPreferences\Symbol\CLDINTF]
STRNFont=Arial,8,N
STRNFont color=0 0 0
QDNMFont=Arial,8,N
QDNMFont color=0 0 0
CNTRFont=Arial,8,N
CNTRFont color=0 0 0
AttributesFont=Arial,8,N
AttributesFont color=0 0 0
OperationsFont=Arial,8,N
OperationsFont color=0 0 0
InnerClassifiersFont=Arial,8,N
InnerClassifiersFont color=0 0 0
LABLFont=Arial,8,N
LABLFont color=0 0 0
AutoAdjustToText=Yes
Keep aspect=No
Keep center=No
Keep size=No
Width=4800
Height=3600
Brush color=205 156 156
Fill Color=Yes
Brush style=6
Brush bitmap mode=12
Brush gradient mode=65
Brush gradient color=255 255 255
Brush background image=
Custom shape=
Custom text mode=0
Pen=1 0 128 0 0
Shadow color=192 192 192
Shadow=0

[DisplayPreferences\Symbol\OOMPORT]
DISPNAMEFont=Arial,8,N
DISPNAMEFont color=0 0 0
AutoAdjustToText=No
Keep aspect=No
Keep center=No
Keep size=No
Width=825
Height=800
Brush color=250 241 211
Fill Color=Yes
Brush style=6
Brush bitmap mode=12
Brush gradient mode=65
Brush gradient color=255 255 255
Brush background image=
Custom shape=
Custom text mode=0
Pen=1 0 128 64 0
Shadow color=192 192 192
Shadow=0

[DisplayPreferences\Symbol\CLDASSC]
SOURCEFont=Arial,8,N
SOURCEFont color=0 0 0
CENTERFont=Arial,8,N
CENTERFont color=0 0 0
DESTINATIONFont=Arial,8,N
DESTINATIONFont color=0 0 0
Line style=2
Source Arrow=24
Center Arrow=24
Target Arrow=24
AutoAdjustToText=Yes
Keep aspect=No
Keep center=No
Keep size=No
Brush color=255 255 255
Fill Color=Yes
Brush style=1
Brush bitmap mode=12
Brush gradient mode=0
Brush gradient color=118 118 118
Brush background image=
Custom shape=
Custom text mode=0
Pen=1 0 128 0 64
Shadow color=192 192 192
Shadow=0

[DisplayPreferences\Symbol\INNERLINK]
Line style=2
Source Arrow=14
Center Arrow=24
Target Arrow=24
Pen=1 0 128 0 64
Shadow color=192 192 192
Shadow=0

[DisplayPreferences\Symbol\CLDACLK]
Line style=2
Source Arrow=24
Center Arrow=24
Target Arrow=24
Pen=2 0 128 0 64
Shadow color=192 192 192
Shadow=0

[DisplayPreferences\Symbol\RQLINK]
CENTERFont=Arial,8,N
CENTERFont color=0 0 0
Line style=2
Source Arrow=24
Center Arrow=24
Target Arrow=6
AutoAdjustToText=Yes
Keep aspect=No
Keep center=No
Keep size=No
Brush color=255 255 255
Fill Color=Yes
Brush style=1
Brush bitmap mode=12
Brush gradient mode=0
Brush gradient color=118 118 118
Brush background image=
Custom shape=
Custom text mode=0
Pen=1 0 128 0 64
Shadow color=192 192 192
Shadow=0

[DisplayPreferences\Symbol\Free Symbol]
Free TextFont=Arial,8,N
Free TextFont color=0 0 0
Line style=2
Source Arrow=24
Center Arrow=24
Target Arrow=24
AutoAdjustToText=Yes
Keep aspect=No
Keep center=No
Keep size=No
Brush color=255 255 255
Fill Color=Yes
Brush style=1
Brush bitmap mode=12
Brush gradient mode=0
Brush gradient color=118 118 118
Brush background image=
Custom shape=
Custom text mode=0
Pen=1 0 128 64 0
Shadow color=192 192 192
Shadow=0</a:DisplayPreferences>
<a:PaperSize>(8268, 11693)</a:PaperSize>
<a:PageMargins>((315,354), (433,354))</a:PageMargins>
<a:PageOrientation>1</a:PageOrientation>
<a:PaperSource>1</a:PaperSource>
<c:Symbols>
<o:AssociationSymbol Id="o6">
<a:CreationDate>1791898306</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-15236,48759), (3135,50678))</a:Rect>
<a:ListOfPoints>((-14836,49821),(2735,49821))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<c:SourceSymbol>
<o:ClassSymbol Ref="o7"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o8"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o9"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o10">
<a:CreationDate>1791899051</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-15236,21694), (43638,39015))</a:Rect>
<a:ListOfPoints>((-14836,38145),(43238,38145),(43238,22094))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<c:SourceSymbol>
<o:ClassSymbol Ref="o7"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o11"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o12"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o13">
<a:CreationDate>1791904651</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-29028,49443), (-24948,76194))</a:Rect>
<a:ListOfPoints>((-27048,49843),(-27048,75794))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<a:AutomaticRoutingState>3</a:AutomaticRoutingState>
<c:SourceSymbol>
<o:ClassSymbol Ref="o7"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o14"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o15"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o16">
<a:CreationDate>1791907382</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-44493,25694), (-30606,27613))</a:Rect>
<a:ListOfPoints>((-31006,26714),(-44093,26714))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<c:SourceSymbol>
<o:ClassSymbol Ref="o7"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o17"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o18"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o19">
<a:CreationDate>1791907482</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-76738,25660), (-61099,27579))</a:Rect>
<a:ListOfPoints>((-76338,26680),(-61499,26680))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<c:SourceSymbol>
<o:ClassSymbol Ref="o20"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o17"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o21"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o22">
<a:CreationDate>1791909416</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-47710,-17444), (-43510,-8704))</a:Rect>
<a:ListOfPoints>((-45610,-17044),(-45610,-9104))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<a:AutomaticRoutingState>3</a:AutomaticRoutingState>
<c:SourceSymbol>
<o:ClassSymbol Ref="o23"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o17"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o24"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o25">
<a:CreationDate>1791910632</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-24901,-3116), (-20821,26096))</a:Rect>
<a:ListOfPoints>((-22921,-2716),(-22921,25696))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<c:SourceSymbol>
<o:ClassSymbol Ref="o26"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o7"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o27"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o28">
<a:CreationDate>1791910635</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-44493,-9464), (-29348,-7545))</a:Rect>
<a:ListOfPoints>((-29748,-8504),(-44093,-8504))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<c:SourceSymbol>
<o:ClassSymbol Ref="o26"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o17"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o29"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o30">
<a:CreationDate>1791911194</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-19626,-40980), (-15546,-23374))</a:Rect>
<a:ListOfPoints>((-17646,-40580),(-17646,-23774))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<c:SourceSymbol>
<o:ClassSymbol Ref="o31"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o26"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o32"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o33">
<a:CreationDate>1792188759</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-5944,-8387), (23929,-6468))</a:Rect>
<a:ListOfPoints>((-5544,-7427),(23529,-7427))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<c:SourceSymbol>
<o:ClassSymbol Ref="o26"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o34"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o35"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o36">
<a:CreationDate>1792189846</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-14761,-33564), (995,-23374))</a:Rect>
<a:ListOfPoints>((595,-32604),(-14361,-32604),(-14361,-23774))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<a:AutomaticRoutingState>2</a:AutomaticRoutingState>
<c:SourceSymbol>
<o:ClassSymbol Ref="o37"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o26"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o38"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o39">
<a:CreationDate>1792190056</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((7782,-48158), (11862,-36958))</a:Rect>
<a:ListOfPoints>((9762,-47758),(9762,-37358))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<c:SourceSymbol>
<o:ClassSymbol Ref="o40"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o37"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o41"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o42">
<a:CreationDate>1792190262</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-40816,44691), (-30606,46610))</a:Rect>
<a:ListOfPoints>((-31006,45750),(-40416,45750))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<c:SourceSymbol>
<o:ClassSymbol Ref="o7"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o43"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o44"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o45">
<a:CreationDate>1792190375</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-80551,-12328), (-61099,9505))</a:Rect>
<a:ListOfPoints>((-78571,-11928),(-78571,9105),(-61499,9105))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<c:SourceSymbol>
<o:ClassSymbol Ref="o46"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o17"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o47"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o48">
<a:CreationDate>1792194884</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-20369,10977), (11867,26096))</a:Rect>
<a:ListOfPoints>((11467,12018),(-19969,12018),(-19969,25696))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<a:AutomaticRoutingState>2</a:AutomaticRoutingState>
<c:SourceSymbol>
<o:ClassSymbol Ref="o49"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o7"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o50"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o51">
<a:CreationDate>1792195704</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-44493,8073), (11867,9992))</a:Rect>
<a:ListOfPoints>((11467,9105),(-44093,9105))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<c:SourceSymbol>
<o:ClassSymbol Ref="o49"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o17"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o52"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o53">
<a:CreationDate>1792195976</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-15236,31009), (-628,32928))</a:Rect>
<a:ListOfPoints>((-1028,32032),(-14836,32032))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<c:SourceSymbol>
<o:ClassSymbol Ref="o54"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o7"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o55"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o56">
<a:CreationDate>1792196193</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-44493,12818), (8388,27183))</a:Rect>
<a:ListOfPoints>((6408,26783),(6408,13218),(-44093,13218))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<c:SourceSymbol>
<o:ClassSymbol Ref="o54"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o17"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o57"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o58">
<a:CreationDate>1792196279</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-58123,50194), (-29816,66723))</a:Rect>
<a:ListOfPoints>((-57723,65887),(-30216,65887),(-30216,50594))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<c:SourceSymbol>
<o:ClassSymbol Ref="o59"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o7"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o60"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o61">
<a:CreationDate>1792196342</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-60423,26914), (-56343,60268))</a:Rect>
<a:ListOfPoints>((-58323,59868),(-58323,27314))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<c:SourceSymbol>
<o:ClassSymbol Ref="o59"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o17"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o62"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o63">
<a:CreationDate>1792196916</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-23821,50194), (1693,73816))</a:Rect>
<a:ListOfPoints>((1293,73416),(-21721,73416),(-21721,50594))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<c:SourceSymbol>
<o:ClassSymbol Ref="o64"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o7"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o65"/>
</c:Object>
</o:AssociationSymbol>
<o:AssociationSymbol Id="o66">
<a:CreationDate>1792197138</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:Rect>((-60147,-39815), (-22521,38545))</a:Rect>
<a:ListOfPoints>((-22921,38145),(-37416,38145),(-37416,-10904),(-58047,-10904),(-58047,-39415))</a:ListOfPoints>
<a:CornerStyle>2</a:CornerStyle>
<a:ArrowStyle>0</a:ArrowStyle>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>CENTER 0 Arial,8,N
SOURCE 0 Arial,8,N</a:FontList>
<a:AutomaticRoutingState>3</a:AutomaticRoutingState>
<c:SourceSymbol>
<o:ClassSymbol Ref="o7"/>
</c:SourceSymbol>
<c:DestinationSymbol>
<o:ClassSymbol Ref="o67"/>
</c:DestinationSymbol>
<c:Object>
<o:Association Ref="o68"/>
</c:Object>
</o:AssociationSymbol>
<o:ClassSymbol Id="o8">
<a:CreationDate>1791417257</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:IconMode>-1</a:IconMode>
<a:Rect>((2735,45052), (18287,54590))</a:Rect>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:FillColor>12632256</a:FillColor>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>STRN 0 Arial,8,N
QDNM 0 Arial,8,N
CNTR 0 Arial,8,N
Attributes 0 Arial,8,N
ClassPrimaryAttribute 0 Arial,8,U
Operations 0 Arial,8,N
InnerClassifiers 0 Arial,8,N
LABL 0 Arial,8,N</a:FontList>
<a:BrushStyle>6</a:BrushStyle>
<a:GradientFillMode>65</a:GradientFillMode>
<a:GradientEndColor>16777215</a:GradientEndColor>
<c:Object>
<o:Class Ref="o69"/>
</c:Object>
</o:ClassSymbol>
<o:ClassSymbol Id="o11">
<a:CreationDate>1791417258</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:IconMode>-1</a:IconMode>
<a:Rect>((35123,-5684), (51353,22094))</a:Rect>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:FillColor>12632256</a:FillColor>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>STRN 0 Arial,8,N
QDNM 0 Arial,8,N
CNTR 0 Arial,8,N
Attributes 0 Arial,8,N
ClassPrimaryAttribute 0 Arial,8,U
Operations 0 Arial,8,N
InnerClassifiers 0 Arial,8,N
LABL 0 Arial,8,N</a:FontList>
<a:BrushStyle>6</a:BrushStyle>
<a:GradientFillMode>65</a:GradientFillMode>
<a:GradientEndColor>16777215</a:GradientEndColor>
<c:Object>
<o:Class Ref="o70"/>
</c:Object>
</o:ClassSymbol>
<o:ClassSymbol Id="o17">
<a:CreationDate>1791417260</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:IconMode>-1</a:IconMode>
<a:Rect>((-61499,-9104), (-44093,27314))</a:Rect>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:FillColor>12632256</a:FillColor>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>STRN 0 Arial,8,N
QDNM 0 Arial,8,N
CNTR 0 Arial,8,N
Attributes 0 Arial,8,N
ClassPrimaryAttribute 0 Arial,8,U
Operations 0 Arial,8,N
InnerClassifiers 0 Arial,8,N
LABL 0 Arial,8,N</a:FontList>
<a:BrushStyle>6</a:BrushStyle>
<a:GradientFillMode>65</a:GradientFillMode>
<a:GradientEndColor>16777215</a:GradientEndColor>
<c:Object>
<o:Class Ref="o71"/>
</c:Object>
</o:ClassSymbol>
<o:ClassSymbol Id="o14">
<a:CreationDate>1791417261</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:IconMode>-1</a:IconMode>
<a:Rect>((-46242,75794), (-14190,94932))</a:Rect>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:FillColor>12632256</a:FillColor>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>STRN 0 Arial,8,N
QDNM 0 Arial,8,N
CNTR 0 Arial,8,N
Attributes 0 Arial,8,N
ClassPrimaryAttribute 0 Arial,8,U
Operations 0 Arial,8,N
InnerClassifiers 0 Arial,8,N
LABL 0 Arial,8,N</a:FontList>
<a:BrushStyle>6</a:BrushStyle>
<a:GradientFillMode>65</a:GradientFillMode>
<a:GradientEndColor>16777215</a:GradientEndColor>
<c:Object>
<o:Class Ref="o72"/>
</c:Object>
</o:ClassSymbol>
<o:ClassSymbol Id="o7">
<a:CreationDate>1791417407</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:IconMode>-1</a:IconMode>
<a:Rect>((-31006,25696), (-14836,50594))</a:Rect>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:FillColor>12632256</a:FillColor>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>STRN 0 Arial,8,N
QDNM 0 Arial,8,N
CNTR 0 Arial,8,N
Attributes 0 Arial,8,N
ClassPrimaryAttribute 0 Arial,8,U
Operations 0 Arial,8,N
InnerClassifiers 0 Arial,8,N
LABL 0 Arial,8,N</a:FontList>
<a:BrushStyle>6</a:BrushStyle>
<a:GradientFillMode>65</a:GradientFillMode>
<a:GradientEndColor>16777215</a:GradientEndColor>
<c:Object>
<o:Class Ref="o73"/>
</c:Object>
</o:ClassSymbol>
<o:ClassSymbol Id="o20">
<a:CreationDate>1791420474</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:IconMode>-1</a:IconMode>
<a:Rect>((-88859,21912), (-76338,31448))</a:Rect>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:FillColor>12632256</a:FillColor>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>STRN 0 Arial,8,N
QDNM 0 Arial,8,N
CNTR 0 Arial,8,N
Attributes 0 Arial,8,N
ClassPrimaryAttribute 0 Arial,8,U
Operations 0 Arial,8,N
InnerClassifiers 0 Arial,8,N
LABL 0 Arial,8,N</a:FontList>
<a:BrushStyle>6</a:BrushStyle>
<a:GradientFillMode>65</a:GradientFillMode>
<a:GradientEndColor>16777215</a:GradientEndColor>
<c:Object>
<o:Class Ref="o74"/>
</c:Object>
</o:ClassSymbol>
<o:ClassSymbol Id="o23">
<a:CreationDate>1791420476</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:IconMode>-1</a:IconMode>
<a:Rect>((-48866,-32338), (-34140,-17044))</a:Rect>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:FillColor>12632256</a:FillColor>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>STRN 0 Arial,8,N
QDNM 0 Arial,8,N
CNTR 0 Arial,8,N
Attributes 0 Arial,8,N
ClassPrimaryAttribute 0 Arial,8,U
Operations 0 Arial,8,N
InnerClassifiers 0 Arial,8,N
LABL 0 Arial,8,N</a:FontList>
<a:BrushStyle>6</a:BrushStyle>
<a:GradientFillMode>65</a:GradientFillMode>
<a:GradientEndColor>16777215</a:GradientEndColor>
<c:Object>
<o:Class Ref="o75"/>
</c:Object>
</o:ClassSymbol>
<o:ClassSymbol Id="o67">
<a:CreationDate>1791420478</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:IconMode>-1</a:IconMode>
<a:Rect>((-67676,-45623), (-48419,-33207))</a:Rect>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:FillColor>12632256</a:FillColor>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>STRN 0 Arial,8,N
QDNM 0 Arial,8,N
CNTR 0 Arial,8,N
Attributes 0 Arial,8,N
ClassPrimaryAttribute 0 Arial,8,U
Operations 0 Arial,8,N
InnerClassifiers 0 Arial,8,N
LABL 0 Arial,8,N</a:FontList>
<a:BrushStyle>6</a:BrushStyle>
<a:GradientFillMode>65</a:GradientFillMode>
<a:GradientEndColor>16777215</a:GradientEndColor>
<c:Object>
<o:Class Ref="o76"/>
</c:Object>
</o:ClassSymbol>
<o:ClassSymbol Id="o26">
<a:CreationDate>1791671571</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:IconMode>-1</a:IconMode>
<a:Rect>((-29748,-23774), (-5544,-2716))</a:Rect>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:FillColor>12632256</a:FillColor>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>STRN 0 Arial,8,N
QDNM 0 Arial,8,N
CNTR 0 Arial,8,N
Attributes 0 Arial,8,N
ClassPrimaryAttribute 0 Arial,8,U
Operations 0 Arial,8,N
InnerClassifiers 0 Arial,8,N
LABL 0 Arial,8,N</a:FontList>
<a:BrushStyle>6</a:BrushStyle>
<a:GradientFillMode>65</a:GradientFillMode>
<a:GradientEndColor>16777215</a:GradientEndColor>
<c:Object>
<o:Class Ref="o77"/>
</c:Object>
</o:ClassSymbol>
<o:ClassSymbol Id="o31">
<a:CreationDate>1791671571</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:IconMode>-1</a:IconMode>
<a:Rect>((-24479,-57798), (-4663,-40580))</a:Rect>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:FillColor>12632256</a:FillColor>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>STRN 0 Arial,8,N
QDNM 0 Arial,8,N
CNTR 0 Arial,8,N
Attributes 0 Arial,8,N
ClassPrimaryAttribute 0 Arial,8,U
Operations 0 Arial,8,N
InnerClassifiers 0 Arial,8,N
LABL 0 Arial,8,N</a:FontList>
<a:BrushStyle>6</a:BrushStyle>
<a:GradientFillMode>65</a:GradientFillMode>
<a:GradientEndColor>16777215</a:GradientEndColor>
<c:Object>
<o:Class Ref="o78"/>
</c:Object>
</o:ClassSymbol>
<o:ClassSymbol Id="o37">
<a:CreationDate>1791671571</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:IconMode>-1</a:IconMode>
<a:Rect>((595,-37358), (18929,-27820))</a:Rect>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:FillColor>12632256</a:FillColor>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>STRN 0 Arial,8,N
QDNM 0 Arial,8,N
CNTR 0 Arial,8,N
Attributes 0 Arial,8,N
ClassPrimaryAttribute 0 Arial,8,U
Operations 0 Arial,8,N
InnerClassifiers 0 Arial,8,N
LABL 0 Arial,8,N</a:FontList>
<a:BrushStyle>6</a:BrushStyle>
<a:GradientFillMode>65</a:GradientFillMode>
<a:GradientEndColor>16777215</a:GradientEndColor>
<c:Object>
<o:Class Ref="o79"/>
</c:Object>
</o:ClassSymbol>
<o:ClassSymbol Id="o40">
<a:CreationDate>1791671571</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:IconMode>-1</a:IconMode>
<a:Rect>((1409,-58256), (17209,-47758))</a:Rect>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:FillColor>12632256</a:FillColor>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>STRN 0 Arial,8,N
QDNM 0 Arial,8,N
CNTR 0 Arial,8,N
Attributes 0 Arial,8,N
ClassPrimaryAttribute 0 Arial,8,U
Operations 0 Arial,8,N
InnerClassifiers 0 Arial,8,N
LABL 0 Arial,8,N</a:FontList>
<a:BrushStyle>6</a:BrushStyle>
<a:GradientFillMode>65</a:GradientFillMode>
<a:GradientEndColor>16777215</a:GradientEndColor>
<c:Object>
<o:Class Ref="o80"/>
</c:Object>
</o:ClassSymbol>
<o:ClassSymbol Id="o43">
<a:CreationDate>1791671571</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:IconMode>-1</a:IconMode>
<a:Rect>((-57204,38581), (-40416,52919))</a:Rect>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:FillColor>12632256</a:FillColor>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>STRN 0 Arial,8,N
QDNM 0 Arial,8,N
CNTR 0 Arial,8,N
Attributes 0 Arial,8,N
ClassPrimaryAttribute 0 Arial,8,U
Operations 0 Arial,8,N
InnerClassifiers 0 Arial,8,N
LABL 0 Arial,8,N</a:FontList>
<a:BrushStyle>6</a:BrushStyle>
<a:GradientFillMode>65</a:GradientFillMode>
<a:GradientEndColor>16777215</a:GradientEndColor>
<c:Object>
<o:Class Ref="o81"/>
</c:Object>
</o:ClassSymbol>
<o:ClassSymbol Id="o46">
<a:CreationDate>1791671571</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:IconMode>-1</a:IconMode>
<a:Rect>((-85204,-27226), (-71938,-11928))</a:Rect>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:FillColor>12632256</a:FillColor>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>STRN 0 Arial,8,N
QDNM 0 Arial,8,N
CNTR 0 Arial,8,N
Attributes 0 Arial,8,N
ClassPrimaryAttribute 0 Arial,8,U
Operations 0 Arial,8,N
InnerClassifiers 0 Arial,8,N
LABL 0 Arial,8,N</a:FontList>
<a:BrushStyle>6</a:BrushStyle>
<a:GradientFillMode>65</a:GradientFillMode>
<a:GradientEndColor>16777215</a:GradientEndColor>
<c:Object>
<o:Class Ref="o82"/>
</c:Object>
</o:ClassSymbol>
<o:ClassSymbol Id="o49">
<a:CreationDate>1791671571</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:IconMode>-1</a:IconMode>
<a:Rect>((11467,4369), (24115,19667))</a:Rect>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:FillColor>12632256</a:FillColor>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>STRN 0 Arial,8,N
QDNM 0 Arial,8,N
CNTR 0 Arial,8,N
Attributes 0 Arial,8,N
ClassPrimaryAttribute 0 Arial,8,U
Operations 0 Arial,8,N
InnerClassifiers 0 Arial,8,N
LABL 0 Arial,8,N</a:FontList>
<a:BrushStyle>6</a:BrushStyle>
<a:GradientFillMode>65</a:GradientFillMode>
<a:GradientEndColor>16777215</a:GradientEndColor>
<c:Object>
<o:Class Ref="o83"/>
</c:Object>
</o:ClassSymbol>
<o:ClassSymbol Id="o54">
<a:CreationDate>1791671571</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:IconMode>-1</a:IconMode>
<a:Rect>((-1028,26783), (13844,37281))</a:Rect>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:FillColor>12632256</a:FillColor>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>STRN 0 Arial,8,N
QDNM 0 Arial,8,N
CNTR 0 Arial,8,N
Attributes 0 Arial,8,N
ClassPrimaryAttribute 0 Arial,8,U
Operations 0 Arial,8,N
InnerClassifiers 0 Arial,8,N
LABL 0 Arial,8,N</a:FontList>
<a:BrushStyle>6</a:BrushStyle>
<a:GradientFillMode>65</a:GradientFillMode>
<a:GradientEndColor>16777215</a:GradientEndColor>
<c:Object>
<o:Class Ref="o84"/>
</c:Object>
</o:ClassSymbol>
<o:ClassSymbol Id="o59">
<a:CreationDate>1791671571</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:IconMode>-1</a:IconMode>
<a:Rect>((-75871,59868), (-57723,71326))</a:Rect>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:FillColor>12632256</a:FillColor>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>STRN 0 Arial,8,N
QDNM 0 Arial,8,N
CNTR 0 Arial,8,N
Attributes 0 Arial,8,N
ClassPrimaryAttribute 0 Arial,8,U
Operations 0 Arial,8,N
InnerClassifiers 0 Arial,8,N
LABL 0 Arial,8,N</a:FontList>
<a:BrushStyle>6</a:BrushStyle>
<a:GradientFillMode>65</a:GradientFillMode>
<a:GradientEndColor>16777215</a:GradientEndColor>
<c:Object>
<o:Class Ref="o85"/>
</c:Object>
</o:ClassSymbol>
<o:ClassSymbol Id="o34">
<a:CreationDate>1792078860</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:IconMode>-1</a:IconMode>
<a:Rect>((23529,-14596), (37761,-258))</a:Rect>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:FillColor>12632256</a:FillColor>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>STRN 0 Arial,8,N
QDNM 0 Arial,8,N
CNTR 0 Arial,8,N
Attributes 0 Arial,8,N
ClassPrimaryAttribute 0 Arial,8,U
Operations 0 Arial,8,N
InnerClassifiers 0 Arial,8,N
LABL 0 Arial,8,N</a:FontList>
<a:BrushStyle>6</a:BrushStyle>
<a:GradientFillMode>65</a:GradientFillMode>
<a:GradientEndColor>16777215</a:GradientEndColor>
<c:Object>
<o:Class Ref="o86"/>
</c:Object>
</o:ClassSymbol>
<o:ClassSymbol Id="o64">
<a:CreationDate>1792196541</a:CreationDate>
<a:ModificationDate>1792493532</a:ModificationDate>
<a:IconMode>-1</a:IconMode>
<a:Rect>((1293,65287), (16967,81545))</a:Rect>
<a:LineColor>0</a:LineColor>
<a:LineWidth>1</a:LineWidth>
<a:FillColor>12632256</a:FillColor>
<a:ShadowColor>12632256</a:ShadowColor>
<a:FontList>STRN 0 Arial,8,N
QDNM 0 Arial,8,N
CNTR 0 Arial,8,N
Attributes 0 Arial,8,N
ClassPrimaryAttribute 0 Arial,8,U
Operations 0 Arial,8,N
InnerClassifiers 0 Arial,8,N
LABL 0 Arial,8,N</a:FontList>
<a:BrushStyle>6</a:BrushStyle>
<a:GradientFillMode>65</a:GradientFillMode>
<a:GradientEndColor>16777215</a:GradientEndColor>
<c:Object>
<o:Class Ref="o87"/>
</c:Object>
</o:ClassSymbol>
</c:Symbols>
</o:ClassDiagram>
</c:ClassDiagrams>
<c:DefaultDiagram>
<o:ClassDiagram Ref="o5"/>
</c:DefaultDiagram>
<c:Classes>
<o:Class Id="o69">
<a:ObjectID>BC405F94-BACA-42FD-8481-B4943AD349AA</a:ObjectID>
<a:Name>PREFERENCE</a:Name>
<a:Code>preference</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791898990</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:UseParentNamespace>0</a:UseParentNamespace>
<c:Attributes>
<o:Attribute Id="o88">
<a:ObjectID>4876EA64-C01C-45AF-A93E-D17258EFB560</a:ObjectID>
<a:Name>id_preference</a:Name>
<a:Code>idPreference</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o89">
<a:ObjectID>D974F089-72B2-4837-9EA3-92F8710DBD16</a:ObjectID>
<a:Name>id_utilisateur</a:Name>
<a:Code>idUtilisateur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o90">
<a:ObjectID>CBED7032-63B5-49FF-978F-723B99D81251</a:ObjectID>
<a:Name>fumeur_accepte</a:Name>
<a:Code>fumeurAccepte</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>boolean</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o91">
<a:ObjectID>30D032DF-6E6A-4603-AE46-1EBA366A646E</a:ObjectID>
<a:Name>musique_acceptee</a:Name>
<a:Code>musiqueAcceptee</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>boolean</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o92">
<a:ObjectID>5FEBEA1A-27CA-43B3-BCB0-1556A0AAA3DF</a:ObjectID>
<a:Name>animaux_acceptes</a:Name>
<a:Code>animauxAcceptes</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>boolean</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o93">
<a:ObjectID>EEEF396D-6C17-4CDF-B644-BC32058115A5</a:ObjectID>
<a:Name>discussion_acceptee</a:Name>
<a:Code>discussionAcceptee</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>boolean</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
</c:Attributes>
<c:Operations>
<o:Operation Id="o94">
<a:ObjectID>680DFFF1-87E6-4A84-A43F-E87F7F88972D</a:ObjectID>
<a:Name>Gérer les préférences de trajet</a:Name>
<a:Code>gRerLesPrFRencesDeTrajet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o95">
<a:ObjectID>CE90C5A5-F573-4741-84E7-0529CBC73F27</a:ObjectID>
<a:Name>Modifier les préférences</a:Name>
<a:Code>modifierLesPrFRences</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
</c:Operations>
<c:Identifiers>
<o:Identifier Id="o96">
<a:ObjectID>EFAC9130-7BDF-4731-A4F9-BC5942C2A539</a:ObjectID>
<a:Name>id_preference</a:Name>
<a:Code>id_preference</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<c:Identifier.Attributes>
<o:Attribute Ref="o88"/>
</c:Identifier.Attributes>
</o:Identifier>
</c:Identifiers>
<c:PrimaryIdentifier>
<o:Identifier Ref="o96"/>
</c:PrimaryIdentifier>
</o:Class>
<o:Class Id="o70">
<a:ObjectID>19C3B14C-BB41-45AD-A7F1-98CFA8F4EB79</a:ObjectID>
<a:Name>VEHICULE</a:Name>
<a:Code>vehicule</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791899725</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:UseParentNamespace>0</a:UseParentNamespace>
<c:Attributes>
<o:Attribute Id="o97">
<a:ObjectID>112FBDEA-A0B7-4796-A44E-402BC9AA5FBC</a:ObjectID>
<a:Name>id_vehicule</a:Name>
<a:Code>idVehicule</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o98">
<a:ObjectID>59855C9D-AF2A-490F-B814-2204F5B91E8F</a:ObjectID>
<a:Name>id_conducteur</a:Name>
<a:Code>idConducteur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o99">
<a:ObjectID>287497B2-E03D-4EFE-B52F-F9546AEE4C9A</a:ObjectID>
<a:Name>marque</a:Name>
<a:Code>marque</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o100">
<a:ObjectID>59EF5262-8669-49C0-9996-6B24DCE7185E</a:ObjectID>
<a:Name>modele</a:Name>
<a:Code>modele</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o101">
<a:ObjectID>9452F5A9-CBBE-4CC6-B968-128DB39F4AA4</a:ObjectID>
<a:Name>annee</a:Name>
<a:Code>annee</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o102">
<a:ObjectID>0F0D6D7D-1843-4A42-AB8C-CAD85CF33A06</a:ObjectID>
<a:Name>puissance_fiscale</a:Name>
<a:Code>puissanceFiscale</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o103">
<a:ObjectID>9F138B62-7B24-4B90-A83F-EDE368C5CCA1</a:ObjectID>
<a:Name>type_energie</a:Name>
<a:Code>typeEnergie</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o104">
<a:ObjectID>9CF2B6B8-BE22-4D58-8130-17D048D26E4A</a:ObjectID>
<a:Name>nombre_places</a:Name>
<a:Code>nombrePlaces</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o105">
<a:ObjectID>A98119ED-0406-4BD0-974E-E60CA116EA9C</a:ObjectID>
<a:Name>consommation_theorique</a:Name>
<a:Code>consommationTheorique</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>float</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o106">
<a:ObjectID>C2A35127-2192-4BDE-80FB-A47D6CA8C914</a:ObjectID>
<a:Name>consommation_reelle</a:Name>
<a:Code>consommationReelle</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>float</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o107">
<a:ObjectID>11079A03-A269-47D5-ABD3-E0DAEF283365</a:ObjectID>
<a:Name>amortissement_par_km</a:Name>
<a:Code>amortissementParKm</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>float</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o108">
<a:ObjectID>3495A8DD-CCF4-4C2E-B18D-0279A8406258</a:ObjectID>
<a:Name>statut_validation</a:Name>
<a:Code>statutValidation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o109">
<a:ObjectID>2EFE9CF7-5BC9-4687-BC1A-8EEBC84F82B6</a:ObjectID>
<a:Name>date_creation</a:Name>
<a:Code>dateCreation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
</c:Attributes>
<c:Operations>
<o:Operation Id="o110">
<a:ObjectID>FBD76B5C-4ABB-482E-956C-A8BD2AE3C93E</a:ObjectID>
<a:Name>Ajouter un véhicule</a:Name>
<a:Code>ajouterUnVHicule</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o111">
<a:ObjectID>CC71286B-4EDC-47B0-98AD-1770787FB7A0</a:ObjectID>
<a:Name>Modifier un véhicule</a:Name>
<a:Code>modifierUnVHicule</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o112">
<a:ObjectID>B750C729-6668-47A2-8088-876E08097647</a:ObjectID>
<a:Name>Supprimer un véhicule</a:Name>
<a:Code>supprimerUnVHicule</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o113">
<a:ObjectID>896147EC-8521-456E-A051-BCBA8146A8F4</a:ObjectID>
<a:Name>Consulter un véhicule</a:Name>
<a:Code>consulterUnVHicule</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o114">
<a:ObjectID>B3203F2D-259B-4573-BBF8-CF3994FFF855</a:ObjectID>
<a:Name>Marque</a:Name>
<a:Code>marque</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o115">
<a:ObjectID>7FF18AE5-DE4B-442A-8A30-E117A072FD26</a:ObjectID>
<a:Name>Modèle</a:Name>
<a:Code>modLe</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o116">
<a:ObjectID>F98AD64B-273D-4AEF-8368-CDD026230A3C</a:ObjectID>
<a:Name>Année</a:Name>
<a:Code>annE</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o117">
<a:ObjectID>B4B7F513-742E-420D-9DC1-3C972A4BC290</a:ObjectID>
<a:Name>Puissance fiscale</a:Name>
<a:Code>puissanceFiscale</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o118">
<a:ObjectID>09CD6FFF-BD04-43BE-A471-2BB9CFA59ABA</a:ObjectID>
<a:Name>Type d&amp;#x27énergie</a:Name>
<a:Code>typeDNergie</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o119">
<a:ObjectID>12ADFBD1-57F8-4C50-9EBF-2EBC23376A28</a:ObjectID>
<a:Name>Nombre de places</a:Name>
<a:Code>nombreDePlaces</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o120">
<a:ObjectID>14BEBC41-BEEC-4C06-99E3-45E64956604A</a:ObjectID>
<a:Name>Consommation théorique</a:Name>
<a:Code>consommationThOrique</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o121">
<a:ObjectID>3EDAF693-A731-4B63-BA33-E3E907D6D0BA</a:ObjectID>
<a:Name>Consommation réelle</a:Name>
<a:Code>consommationRElle</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o122">
<a:ObjectID>C4C01706-51B5-4906-9820-86BC37F9627F</a:ObjectID>
<a:Name>Amortissement par kilomètre</a:Name>
<a:Code>amortissementParKilomTre</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o123">
<a:ObjectID>94567FD3-7E8B-42F9-81D2-3985AA879827</a:ObjectID>
<a:Name>Association véhicule/conducteur</a:Name>
<a:Code>associationVHiculeConducteur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
</c:Operations>
<c:Identifiers>
<o:Identifier Id="o124">
<a:ObjectID>4EC70E86-A2A3-4A6A-9E6D-BFE9BDA21A1B</a:ObjectID>
<a:Name>id_vehicule</a:Name>
<a:Code>id_vehicule</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<c:Identifier.Attributes>
<o:Attribute Ref="o97"/>
</c:Identifier.Attributes>
</o:Identifier>
</c:Identifiers>
<c:PrimaryIdentifier>
<o:Identifier Ref="o124"/>
</c:PrimaryIdentifier>
</o:Class>
<o:Class Id="o71">
<a:ObjectID>090ACF3D-BFAE-44D2-AED3-D9562B8C50D3</a:ObjectID>
<a:Name>TRAJET</a:Name>
<a:Code>trajet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792197166</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:UseParentNamespace>0</a:UseParentNamespace>
<c:Attributes>
<o:Attribute Id="o125">
<a:ObjectID>1B607AA0-1610-4231-8C75-3515817A1D7A</a:ObjectID>
<a:Name>id_trajet</a:Name>
<a:Code>idTrajet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o126">
<a:ObjectID>E26431C3-8B9C-42B3-9B2A-63211B915359</a:ObjectID>
<a:Name>id_conducteur</a:Name>
<a:Code>idConducteur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o127">
<a:ObjectID>83839A8E-3AFB-450D-8A1C-AE4BEF4580BC</a:ObjectID>
<a:Name>id_vehicule</a:Name>
<a:Code>idVehicule</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o128">
<a:ObjectID>0EDB6A23-AF6F-469D-85B8-3561BC79017C</a:ObjectID>
<a:Name>lieu_depart</a:Name>
<a:Code>lieuDepart</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o129">
<a:ObjectID>F86FF030-60C8-4AF7-85F4-304338DEEC45</a:ObjectID>
<a:Name>destination</a:Name>
<a:Code>destination</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o130">
<a:ObjectID>F8EE32AB-DF21-4E4D-BA72-073AC302402D</a:ObjectID>
<a:Name>position_depart</a:Name>
<a:Code>positionDepart</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o131">
<a:ObjectID>6B05DDD5-5D07-4C0A-8852-F40668EE4530</a:ObjectID>
<a:Name>position_destination</a:Name>
<a:Code>positionDestination</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o132">
<a:ObjectID>3E447CC4-32F6-4E87-BE87-C524F70F8AB7</a:ObjectID>
<a:Name>date_depart</a:Name>
<a:Code>dateDepart</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o133">
<a:ObjectID>E799C20B-324C-4A2C-B903-39C5158B99ED</a:ObjectID>
<a:Name>heure_depart</a:Name>
<a:Code>heureDepart</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o134">
<a:ObjectID>5C4C8D05-7ACB-4B4F-9BB1-3BBADAA81246</a:ObjectID>
<a:Name>flexibilite_minutes</a:Name>
<a:Code>flexibiliteMinutes</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o135">
<a:ObjectID>0C0C78DC-9EFD-4EB9-BE0D-61B2DD78312E</a:ObjectID>
<a:Name>nombre_places_total</a:Name>
<a:Code>nombrePlacesTotal</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o136">
<a:ObjectID>3EFC2EEB-0E29-4C3D-A02C-3CF1B8B1DF58</a:ObjectID>
<a:Name>nombre_places_disponibles</a:Name>
<a:Code>nombrePlacesDisponibles</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o137">
<a:ObjectID>6F1EEEA5-4179-4A29-9EE3-5ED577796B76</a:ObjectID>
<a:Name>mode_reservation</a:Name>
<a:Code>modeReservation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o138">
<a:ObjectID>B8E95F32-0860-4B43-919D-D4FCCF078BA3</a:ObjectID>
<a:Name>taille_bagage_acceptee</a:Name>
<a:Code>tailleBagageAcceptee</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o139">
<a:ObjectID>C84EFA10-AE91-42CB-A3CA-D0BB210D6056</a:ObjectID>
<a:Name>statut</a:Name>
<a:Code>statut</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o140">
<a:ObjectID>A3411198-DC98-474E-897D-2BB5474FA7FA</a:ObjectID>
<a:Name>femmes_uniquement</a:Name>
<a:Code>femmesUniquement</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>boolean</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o141">
<a:ObjectID>F573D9AB-A7B7-456A-BBF8-169A6815D38F</a:ObjectID>
<a:Name>distance_km</a:Name>
<a:Code>distanceKm</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>float</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o142">
<a:ObjectID>1C86E020-8443-4196-84FB-353C9756B633</a:ObjectID>
<a:Name>denivele</a:Name>
<a:Code>denivele</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o143">
<a:ObjectID>B6F843E6-796B-49E4-BAF0-C3FA80CFF403</a:ObjectID>
<a:Name>type_route</a:Name>
<a:Code>typeRoute</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o144">
<a:ObjectID>8FD98961-477D-49E2-B417-C78176179A82</a:ObjectID>
<a:Name>montant_peages</a:Name>
<a:Code>montantPeages</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>float</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o145">
<a:ObjectID>E97200C8-BB03-475D-A6D5-7E1FC6C751AA</a:ObjectID>
<a:Name>date_creation</a:Name>
<a:Code>dateCreation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
</c:Attributes>
<c:Operations>
<o:Operation Id="o146">
<a:ObjectID>520A9EE2-27B4-4F0E-B53F-D880491513A5</a:ObjectID>
<a:Name>Créer un trajet</a:Name>
<a:Code>crErUnTrajet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o147">
<a:ObjectID>C52A3283-7BAA-41E4-9CFF-C0D1D0DE9F7E</a:ObjectID>
<a:Name>Modifier un trajet</a:Name>
<a:Code>modifierUnTrajet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o148">
<a:ObjectID>AB2AA1E1-8027-4BD1-BEE7-B371AAC6ED2F</a:ObjectID>
<a:Name>Annuler un trajet</a:Name>
<a:Code>annulerUnTrajet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o149">
<a:ObjectID>3D82C2E0-EE8B-498A-9397-192EE23DE04B</a:ObjectID>
<a:Name>Publier un trajet</a:Name>
<a:Code>publierUnTrajet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o150">
<a:ObjectID>1A4A5415-2B62-48E5-AA8D-9F38E2CBA64C</a:ObjectID>
<a:Name>Consulter ses trajets</a:Name>
<a:Code>consulterSesTrajets</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o151">
<a:ObjectID>0A122CA9-FE99-4699-B1BA-5840F032F3DD</a:ObjectID>
<a:Name>Définir départ</a:Name>
<a:Code>dFinirDPart</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o152">
<a:ObjectID>F3C8D017-CF21-4017-8BD6-E0171174FC31</a:ObjectID>
<a:Name>Définir destination</a:Name>
<a:Code>dFinirDestination</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o153">
<a:ObjectID>CE89C1AC-27C7-4C1D-B04F-AA4259590506</a:ObjectID>
<a:Name>Définir date</a:Name>
<a:Code>dFinirDate</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o154">
<a:ObjectID>5C717623-2159-4244-A9A3-54842BF29A9E</a:ObjectID>
<a:Name>Définir heure</a:Name>
<a:Code>dFinirHeure</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o155">
<a:ObjectID>740D5011-730B-4415-A365-5C4195809097</a:ObjectID>
<a:Name>Définir flexibilité de 15 à 30 minutes</a:Name>
<a:Code>dFinirFlexibilitDe1530Minutes</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o156">
<a:ObjectID>C14866CC-212A-4CB6-A48E-DB6728964247</a:ObjectID>
<a:Name>Définir nombre de places</a:Name>
<a:Code>dFinirNombreDePlaces</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o157">
<a:ObjectID>CD372090-A6E5-4368-98B7-E383F7C1050C</a:ObjectID>
<a:Name>Définir mode de réservation</a:Name>
<a:Code>dFinirModeDeRServation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o158">
<a:ObjectID>687262CD-3A7E-48A8-A163-7B41322A2BE5</a:ObjectID>
<a:Name>Définir taille des bagages</a:Name>
<a:Code>dFinirTailleDesBagages</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o159">
<a:ObjectID>33E77476-29ED-45E7-A672-F0DEA4459606</a:ObjectID>
<a:Name>Définir les préférences du trajet</a:Name>
<a:Code>dFinirLesPrFRencesDuTrajet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o160">
<a:ObjectID>AB543322-0C32-45E5-88BD-FA4CE19C14D7</a:ObjectID>
<a:Name>Terminer un trajet</a:Name>
<a:Code>terminerUnTrajet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
</c:Operations>
<c:Identifiers>
<o:Identifier Id="o161">
<a:ObjectID>9304B62B-4979-4F26-828D-745F74B5CEFE</a:ObjectID>
<a:Name>id_trajet</a:Name>
<a:Code>id_trajet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<c:Identifier.Attributes>
<o:Attribute Ref="o125"/>
</c:Identifier.Attributes>
</o:Identifier>
</c:Identifiers>
<c:PrimaryIdentifier>
<o:Identifier Ref="o161"/>
</c:PrimaryIdentifier>
</o:Class>
<o:Class Id="o72">
<a:ObjectID>5D7E1071-4774-46C5-92A5-4FB932B8E9C1</a:ObjectID>
<a:Name>DOCUMENT</a:Name>
<a:Code>document</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791906389</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:UseParentNamespace>0</a:UseParentNamespace>
<c:Attributes>
<o:Attribute Id="o162">
<a:ObjectID>348E9D77-EE94-4B5F-8E4A-B254429E5785</a:ObjectID>
<a:Name>id_document</a:Name>
<a:Code>idDocument</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o163">
<a:ObjectID>66D7CF21-FF45-41FC-B618-2D5EF85A857D</a:ObjectID>
<a:Name>id_utilisateur</a:Name>
<a:Code>idUtilisateur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o164">
<a:ObjectID>F15C4233-77EF-4416-8F9E-D53BF2F4AFDA</a:ObjectID>
<a:Name>id_vehicule</a:Name>
<a:Code>idVehicule</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o165">
<a:ObjectID>006AB6BB-E0E8-4E4D-A6C2-6556C7B3BC45</a:ObjectID>
<a:Name>id_administrateur</a:Name>
<a:Code>idAdministrateur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o166">
<a:ObjectID>1CC7C70F-78CB-4224-A626-4B8FC3DF46CE</a:ObjectID>
<a:Name>type_document</a:Name>
<a:Code>typeDocument</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o167">
<a:ObjectID>1E9E7885-EFED-4195-A173-B1F599178C5D</a:ObjectID>
<a:Name>fichier</a:Name>
<a:Code>fichier</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o168">
<a:ObjectID>EFEBDC83-EFAB-4E9B-97F3-953F6210A739</a:ObjectID>
<a:Name>statut_validation</a:Name>
<a:Code>statutValidation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o169">
<a:ObjectID>AB7F56B0-60FA-467E-A8AE-7BD2E7BE3DDF</a:ObjectID>
<a:Name>commentaire_admin</a:Name>
<a:Code>commentaireAdmin</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o170">
<a:ObjectID>0D73AAAB-FCA5-4A02-9F7B-7EF8B12FE4FC</a:ObjectID>
<a:Name>date_soumission</a:Name>
<a:Code>dateSoumission</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o171">
<a:ObjectID>60B5B3E1-5BF1-4DD9-821B-9242B720F938</a:ObjectID>
<a:Name>date_validation</a:Name>
<a:Code>dateValidation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
</c:Attributes>
<c:Operations>
<o:Operation Id="o172">
<a:ObjectID>9D220517-2A17-42D6-A3EC-7194F2FAB320</a:ObjectID>
<a:Name>Ajouter le permis de conduire</a:Name>
<a:Code>ajouterLePermisDeConduire</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o173">
<a:ObjectID>03C70A35-6731-4754-9824-6C9D93B0B46A</a:ObjectID>
<a:Name>Ajouter la carte grise</a:Name>
<a:Code>ajouterLaCarteGrise</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o174">
<a:ObjectID>23BFBA4B-22EA-41C2-88CA-52DBDB49CC7B</a:ObjectID>
<a:Name>Soumettre les documents</a:Name>
<a:Code>soumettreLesDocuments</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o175">
<a:ObjectID>5D2330FD-E049-46AD-99DF-99995F5AA7AF</a:ObjectID>
<a:Name>Consulter le statut de validation</a:Name>
<a:Code>consulterLeStatutDeValidation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o176">
<a:ObjectID>F499F8C0-D2F6-4590-B24D-CD8AA08131D8</a:ObjectID>
<a:Name>Valider un document</a:Name>
<a:Code>validerUnDocument</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o177">
<a:ObjectID>27D3CDC3-5471-40DA-982C-247DB09B7733</a:ObjectID>
<a:Name>Refuser un document</a:Name>
<a:Code>refuserUnDocument</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o178">
<a:ObjectID>330AAAAA-138A-4483-9AF2-AE6915F6F66F</a:ObjectID>
<a:Name>Ajouter un commentaire de refus</a:Name>
<a:Code>ajouterUnCommentaireDeRefus</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o179">
<a:ObjectID>6046B3A0-D174-4293-B3FE-04958B70440C</a:ObjectID>
<a:Name>Bloquer la publication d&amp;#x27un trajet si le conducteur n&amp;#x27est pas validé</a:Name>
<a:Code>bloquerLaPublicationDUnTrajetSiLeConducteurNEstPasValid</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
</c:Operations>
<c:Identifiers>
<o:Identifier Id="o180">
<a:ObjectID>9F9E5958-003A-4EF0-9533-0D2E37A00432</a:ObjectID>
<a:Name>id_document</a:Name>
<a:Code>id_document</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<c:Identifier.Attributes>
<o:Attribute Ref="o162"/>
</c:Identifier.Attributes>
</o:Identifier>
</c:Identifiers>
<c:PrimaryIdentifier>
<o:Identifier Ref="o180"/>
</c:PrimaryIdentifier>
</o:Class>
<o:Class Id="o73">
<a:ObjectID>01F7ECB5-D524-4718-BF42-6E104545B52C</a:ObjectID>
<a:Name>UTILISATEUR</a:Name>
<a:Code>utilisateur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196971</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:UseParentNamespace>0</a:UseParentNamespace>
<c:Attributes>
<o:Attribute Id="o181">
<a:ObjectID>F1D8A4DC-674F-488B-8B54-DECA55EFD0CD</a:ObjectID>
<a:Name>id_utilisateur</a:Name>
<a:Code>idUtilisateur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o182">
<a:ObjectID>46FD8038-21FE-4714-B86F-ABB811CEA3F6</a:ObjectID>
<a:Name>prenom</a:Name>
<a:Code>prenom</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o183">
<a:ObjectID>7091A64A-9D81-443E-9CE1-835647EAC1D8</a:ObjectID>
<a:Name>nom</a:Name>
<a:Code>nom</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o184">
<a:ObjectID>EB44AEA9-5844-47E3-9E94-E74B064233CE</a:ObjectID>
<a:Name>email</a:Name>
<a:Code>email</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o185">
<a:ObjectID>5E976810-B53B-422F-8E9D-CA15EF9F93DA</a:ObjectID>
<a:Name>mot_de_passe</a:Name>
<a:Code>motDePasse</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o186">
<a:ObjectID>35A9C057-E3B6-4708-87D7-6AD2EA617484</a:ObjectID>
<a:Name>photo_profil</a:Name>
<a:Code>photoProfil</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o187">
<a:ObjectID>67F5FFC6-5A4C-4F6B-8DE7-3637AD8F6EB2</a:ObjectID>
<a:Name>bio</a:Name>
<a:Code>bio</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o188">
<a:ObjectID>12ED52E5-C2EF-4EF3-8CD4-C15642CFC382</a:ObjectID>
<a:Name>role</a:Name>
<a:Code>role</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o189">
<a:ObjectID>CCB15096-392B-4EF2-87F2-82C1CC0B7F3E</a:ObjectID>
<a:Name>statut</a:Name>
<a:Code>statut</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o190">
<a:ObjectID>C7A60383-A7DB-4083-98AF-327E9079D131</a:ObjectID>
<a:Name>date_creation</a:Name>
<a:Code>dateCreation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
</c:Attributes>
<c:Operations>
<o:Operation Id="o191">
<a:ObjectID>40D06BEF-5353-4A2E-A80B-CC1DB6CA535F</a:ObjectID>
<a:Name>Inscription</a:Name>
<a:Code>inscription</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o192">
<a:ObjectID>0B88B035-B0F2-4DD4-A270-62C5CD495AEA</a:ObjectID>
<a:Name>Connexion</a:Name>
<a:Code>connexion</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o193">
<a:ObjectID>CBA10F33-D3A6-4F2B-9E15-7C6CE47C88D0</a:ObjectID>
<a:Name>Déconnexion</a:Name>
<a:Code>dConnexion</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o194">
<a:ObjectID>2E5662DC-9F4B-4959-A4E0-714210DCA02C</a:ObjectID>
<a:Name>Vérification OTP</a:Name>
<a:Code>vRificationOTP</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o195">
<a:ObjectID>DB01BCCB-3C68-4B2A-AB9F-C495002AB1B9</a:ObjectID>
<a:Name>Connexion avec Google</a:Name>
<a:Code>connexionAvecGoogle</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o196">
<a:ObjectID>1FD8CD30-04CA-4C2D-A312-5F2C895F74CB</a:ObjectID>
<a:Name>Gestion du profil</a:Name>
<a:Code>gestionDuProfil</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o197">
<a:ObjectID>939F4954-5C78-4150-9506-44F0D3219A61</a:ObjectID>
<a:Name>Photo de profil</a:Name>
<a:Code>photoDeProfil</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o198">
<a:ObjectID>E3F2B522-ECD3-414B-B4B5-A534E572E5B7</a:ObjectID>
<a:Name>Biographie</a:Name>
<a:Code>biographie</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o199">
<a:ObjectID>88761430-F8B9-420B-9690-0793F4420055</a:ObjectID>
<a:Name>Préférences de trajet</a:Name>
<a:Code>prFRencesDeTrajet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o200">
<a:ObjectID>169B1F7D-46A3-4D77-A2C8-15943FCFC585</a:ObjectID>
<a:Name>Gestion des rôles</a:Name>
<a:Code>gestionDesRLes</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o201">
<a:ObjectID>2EF78783-B277-43C2-BBA7-9051D90897AD</a:ObjectID>
<a:Name>Modification du profil</a:Name>
<a:Code>modificationDuProfil</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o202">
<a:ObjectID>DFBDFDD3-E0D0-4458-954C-76E0853CC43F</a:ObjectID>
<a:Name>Modification du mot de passe</a:Name>
<a:Code>modificationDuMotDePasse</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o203">
<a:ObjectID>36C4D2AC-3DA4-49E1-AA8A-C72508D172EE</a:ObjectID>
<a:Name>Réinitialisation du mot de passe</a:Name>
<a:Code>rInitialisationDuMotDePasse</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o204">
<a:ObjectID>DF010633-5BA5-4D15-86F5-748DD31845CE</a:ObjectID>
<a:Name>Désactivation du compte</a:Name>
<a:Code>dSactivationDuCompte</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
</c:Operations>
<c:Identifiers>
<o:Identifier Id="o205">
<a:ObjectID>94FBDDE9-476A-4B98-BA23-97DB7018735B</a:ObjectID>
<a:Name>id_utilisateur</a:Name>
<a:Code>id_utilisateur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<c:Identifier.Attributes>
<o:Attribute Ref="o181"/>
</c:Identifier.Attributes>
</o:Identifier>
</c:Identifiers>
<c:PrimaryIdentifier>
<o:Identifier Ref="o205"/>
</c:PrimaryIdentifier>
</o:Class>
<o:Class Id="o74">
<a:ObjectID>C2DF4AF3-2ECC-4A1C-AA05-39D63A8AA4E6</a:ObjectID>
<a:Name>ESCALE</a:Name>
<a:Code>escale</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791908284</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:UseParentNamespace>0</a:UseParentNamespace>
<c:Attributes>
<o:Attribute Id="o206">
<a:ObjectID>1257AD94-70B9-448B-8622-BF2089C935A2</a:ObjectID>
<a:Name>id_escale</a:Name>
<a:Code>idEscale</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o207">
<a:ObjectID>3329EA7B-E1BA-47D3-A8D3-E95F22B2843C</a:ObjectID>
<a:Name>id_trajet</a:Name>
<a:Code>idTrajet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o208">
<a:ObjectID>EB7A00D6-A875-4FE0-BEC5-96E8F03A955A</a:ObjectID>
<a:Name>ordre</a:Name>
<a:Code>ordre</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o209">
<a:ObjectID>E37C4F23-53E2-4DFC-B140-1F1D869C54D2</a:ObjectID>
<a:Name>lieu</a:Name>
<a:Code>lieu</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o210">
<a:ObjectID>59CA1AB6-DA7A-4E78-9465-343539B2E317</a:ObjectID>
<a:Name>position</a:Name>
<a:Code>position</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
</c:Attributes>
<c:Operations>
<o:Operation Id="o211">
<a:ObjectID>B15DFC9C-9EE1-4864-A94E-122A0F4F2310</a:ObjectID>
<a:Name>Ajouter une escale</a:Name>
<a:Code>ajouterUneEscale</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o212">
<a:ObjectID>5745C313-A249-4E64-A93B-D80B996537FA</a:ObjectID>
<a:Name>Modifier une escale</a:Name>
<a:Code>modifierUneEscale</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o213">
<a:ObjectID>776A1F3B-10B4-46B4-A15F-9581B08BA52D</a:ObjectID>
<a:Name>Supprimer une escale</a:Name>
<a:Code>supprimerUneEscale</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
</c:Operations>
<c:Identifiers>
<o:Identifier Id="o214">
<a:ObjectID>48950601-7509-4FDF-8280-23BEE64EE3D9</a:ObjectID>
<a:Name>id_escale</a:Name>
<a:Code>id_escale</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<c:Identifier.Attributes>
<o:Attribute Ref="o206"/>
</c:Identifier.Attributes>
</o:Identifier>
</c:Identifiers>
<c:PrimaryIdentifier>
<o:Identifier Ref="o214"/>
</c:PrimaryIdentifier>
</o:Class>
<o:Class Id="o75">
<a:ObjectID>1A12AF9E-4DE0-43D5-95FA-4176AFE32C29</a:ObjectID>
<a:Name>TARIFICATION</a:Name>
<a:Code>tarification</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791909478</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:UseParentNamespace>0</a:UseParentNamespace>
<c:Attributes>
<o:Attribute Id="o215">
<a:ObjectID>51643EEE-4800-4199-B1D9-4077A14BD4C6</a:ObjectID>
<a:Name>id_tarification</a:Name>
<a:Code>idTarification</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o216">
<a:ObjectID>252CD5EB-E34D-43CD-B2EE-DFCF014E7E54</a:ObjectID>
<a:Name>id_trajet</a:Name>
<a:Code>idTrajet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o217">
<a:ObjectID>6EA05B25-AA72-41AF-A93B-F28B52003293</a:ObjectID>
<a:Name>prix_ia_par_passager</a:Name>
<a:Code>prixIaParPassager</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>float</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o218">
<a:ObjectID>48F562A3-4A9F-4ECD-A832-BFCFD04179EF</a:ObjectID>
<a:Name>prix_propose_par_passager</a:Name>
<a:Code>prixProposeParPassager</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>float</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o219">
<a:ObjectID>C9C6F0A7-4361-4B04-9892-5F81FEE0EFA9</a:ObjectID>
<a:Name>prix_final_par_passager</a:Name>
<a:Code>prixFinalParPassager</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>float</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o220">
<a:ObjectID>6116ADA0-D352-4735-96B3-4F7677C573C7</a:ObjectID>
<a:Name>marge_ajustement</a:Name>
<a:Code>margeAjustement</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>float</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o221">
<a:ObjectID>BCE7E62B-268C-4DAC-AD72-C3BAF6C7C955</a:ObjectID>
<a:Name>date_prediction</a:Name>
<a:Code>datePrediction</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o222">
<a:ObjectID>B190D6AC-25ED-4233-AAD6-7184DED2657F</a:ObjectID>
<a:Name>version_modele</a:Name>
<a:Code>versionModele</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
</c:Attributes>
<c:Operations>
<o:Operation Id="o223">
<a:ObjectID>FB58868B-9E79-410E-ACD8-461FC5E8F458</a:ObjectID>
<a:Name>Calculer le prix avec IA</a:Name>
<a:Code>calculerLePrixAvecIA</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o224">
<a:ObjectID>3062ACC9-D2FB-4621-A5D0-4D12A7FF9234</a:ObjectID>
<a:Name>Obtenir le prix proposé</a:Name>
<a:Code>obtenirLePrixPropos</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o225">
<a:ObjectID>1536811D-F972-4F34-8513-3A817DE75C00</a:ObjectID>
<a:Name>Afficher le prix par passager</a:Name>
<a:Code>afficherLePrixParPassager</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o226">
<a:ObjectID>3E1458F3-4284-4CA1-B29B-2D0F3B1FA1A3</a:ObjectID>
<a:Name>Modifier le prix de ±10 %</a:Name>
<a:Code>modifierLePrixDe10</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o227">
<a:ObjectID>107D5669-4966-4A41-A365-059E0A366500</a:ObjectID>
<a:Name>Enregistrer le prix final</a:Name>
<a:Code>enregistrerLePrixFinal</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o228">
<a:ObjectID>8978805F-CBCF-41E0-9707-83F515D114B2</a:ObjectID>
<a:Name>Versionner le modèle</a:Name>
<a:Code>versionnerLeModLe</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
</c:Operations>
<c:Identifiers>
<o:Identifier Id="o229">
<a:ObjectID>7C76B87F-3F78-4827-81F2-AC193E493ABD</a:ObjectID>
<a:Name>id_tarification</a:Name>
<a:Code>id_tarification</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<c:Identifier.Attributes>
<o:Attribute Ref="o215"/>
</c:Identifier.Attributes>
</o:Identifier>
</c:Identifiers>
<c:PrimaryIdentifier>
<o:Identifier Ref="o229"/>
</c:PrimaryIdentifier>
</o:Class>
<o:Class Id="o76">
<a:ObjectID>A7EF132A-F3DF-4FBA-B5B7-C2CBC23A998E</a:ObjectID>
<a:Name>PARAMETRE_TARIFICATION</a:Name>
<a:Code>parametreTARIFICATION</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792197166</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:UseParentNamespace>0</a:UseParentNamespace>
<c:Attributes>
<o:Attribute Id="o230">
<a:ObjectID>D4D4617B-C882-4ADD-9504-B6E251744583</a:ObjectID>
<a:Name>id_parametre</a:Name>
<a:Code>idParametre</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o231">
<a:ObjectID>60685B5F-FDD0-406C-98C7-6F11E8B5AA34</a:ObjectID>
<a:Name>id_administrateur</a:Name>
<a:Code>idAdministrateur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o232">
<a:ObjectID>6C922CD7-5203-45E3-9464-97BDB8A6396A</a:ObjectID>
<a:Name>nom_parametre</a:Name>
<a:Code>nomParametre</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o233">
<a:ObjectID>75D9985E-38A2-4480-A805-F05803B71A6A</a:ObjectID>
<a:Name>valeur</a:Name>
<a:Code>valeur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>float</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o234">
<a:ObjectID>BABEE112-5FD2-406D-BD0F-A5767848267E</a:ObjectID>
<a:Name>unite</a:Name>
<a:Code>unite</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o235">
<a:ObjectID>22716A96-C5D2-4BAA-8D16-4288E14F62CA</a:ObjectID>
<a:Name>description</a:Name>
<a:Code>description</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o236">
<a:ObjectID>0624748F-8681-4994-92CB-C72484A89BBE</a:ObjectID>
<a:Name>actif</a:Name>
<a:Code>actif</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>boolean</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o237">
<a:ObjectID>64858210-E5C7-4333-BFE8-3D1586649E60</a:ObjectID>
<a:Name>date_modification</a:Name>
<a:Code>dateModification</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
</c:Attributes>
<c:Operations>
<o:Operation Id="o238">
<a:ObjectID>A3B94B2F-55A9-4668-9214-CA7994D4EE4F</a:ObjectID>
<a:Name>Gérer les paramètres de tarification</a:Name>
<a:Code>gRerLesParamTresDeTarification</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o239">
<a:ObjectID>204A0696-3C4C-4040-88BA-150CE217E600</a:ObjectID>
<a:Name>Modifier le prix de référence du carburant</a:Name>
<a:Code>modifierLePrixDeRFRenceDuCarburant</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o240">
<a:ObjectID>E555B9FF-F12C-46E3-9DEF-0B223C62AD0C</a:ObjectID>
<a:Name>Modifier les coefficients IA</a:Name>
<a:Code>modifierLesCoefficientsIA</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
</c:Operations>
<c:Identifiers>
<o:Identifier Id="o241">
<a:ObjectID>BF7D44DF-7937-4851-8F67-A5CBB44C5897</a:ObjectID>
<a:Name>id_parametre</a:Name>
<a:Code>id_parametre</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<c:Identifier.Attributes>
<o:Attribute Ref="o230"/>
</c:Identifier.Attributes>
</o:Identifier>
</c:Identifiers>
<c:PrimaryIdentifier>
<o:Identifier Ref="o241"/>
</c:PrimaryIdentifier>
</o:Class>
<o:Class Id="o77">
<a:ObjectID>347378D6-0A2E-4083-B144-333841911270</a:ObjectID>
<a:Name>RESERVATION</a:Name>
<a:Code>reservation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792189968</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:UseParentNamespace>0</a:UseParentNamespace>
<c:Attributes>
<o:Attribute Id="o242">
<a:ObjectID>5DB7446D-E659-44F8-8080-3791B4EE8778</a:ObjectID>
<a:Name>id_reservation</a:Name>
<a:Code>idReservation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o243">
<a:ObjectID>C2338BBA-28AC-4D23-99C2-4FF6D86A10BB</a:ObjectID>
<a:Name>id_trajet</a:Name>
<a:Code>idTrajet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o244">
<a:ObjectID>E306F7CC-F871-4764-A7E1-96EE56CBC970</a:ObjectID>
<a:Name>id_passager</a:Name>
<a:Code>idPassager</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o245">
<a:ObjectID>74644D66-69FD-43E9-B4CD-D5D10FE16C3E</a:ObjectID>
<a:Name>nombre_places</a:Name>
<a:Code>nombrePlaces</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o246">
<a:ObjectID>912F7272-4205-45F3-B895-589D8C739010</a:ObjectID>
<a:Name>statut</a:Name>
<a:Code>statut</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o247">
<a:ObjectID>9F223C47-6EBB-4A51-9F0B-0C25AC8F6428</a:ObjectID>
<a:Name>date_demande</a:Name>
<a:Code>dateDemande</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o248">
<a:ObjectID>06C075FC-6188-42C2-9B36-B255B0EE0463</a:ObjectID>
<a:Name>date_reponse</a:Name>
<a:Code>dateReponse</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o249">
<a:ObjectID>C9CB8195-03A5-493D-90CF-B506410D1D41</a:ObjectID>
<a:Name>code_embarquement</a:Name>
<a:Code>codeEmbarquement</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
</c:Attributes>
<c:Operations>
<o:Operation Id="o250">
<a:ObjectID>90E6ED10-B062-4751-B96B-E08C768FDAEF</a:ObjectID>
<a:Name>Demander une réservation</a:Name>
<a:Code>demanderUneRServation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o251">
<a:ObjectID>91DBD573-9C58-46F0-BE3F-6C31DB41C257</a:ObjectID>
<a:Name>Réserver une ou plusieurs places</a:Name>
<a:Code>rServerUneOuPlusieursPlaces</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o252">
<a:ObjectID>EB93713C-0970-4951-9F4A-E881AC5C0A5B</a:ObjectID>
<a:Name>Vérifier les places disponibles</a:Name>
<a:Code>vRifierLesPlacesDisponibles</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o253">
<a:ObjectID>B244CCA1-FBD4-42AD-9AC4-4663A28A0D75</a:ObjectID>
<a:Name>Réservation automatique</a:Name>
<a:Code>rServationAutomatique</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o254">
<a:ObjectID>CDA01487-E012-4855-BDD7-F204109D703A</a:ObjectID>
<a:Name>Réservation manuelle</a:Name>
<a:Code>rServationManuelle</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o255">
<a:ObjectID>8F3B9D74-944C-4FB8-ACE7-8EA26DC04E99</a:ObjectID>
<a:Name>Accepter une réservation</a:Name>
<a:Code>accepterUneRServation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o256">
<a:ObjectID>0053A4DC-6710-46E8-9B8E-60B350D51B0E</a:ObjectID>
<a:Name>Refuser une réservation</a:Name>
<a:Code>refuserUneRServation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o257">
<a:ObjectID>7B5E55AB-CC45-4E90-94A0-36E2DAC41E15</a:ObjectID>
<a:Name>Annuler une réservation</a:Name>
<a:Code>annulerUneRServation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o258">
<a:ObjectID>6168ADF7-2998-41BC-8484-06BB760C7EBF</a:ObjectID>
<a:Name>Consulter ses réservations</a:Name>
<a:Code>consulterSesRServations</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o259">
<a:ObjectID>FADF5D15-CCAE-471F-8888-CC975AC0484D</a:ObjectID>
<a:Name>Consulter l&amp;#x27historique</a:Name>
<a:Code>consulterLHistorique</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o260">
<a:ObjectID>4331BAAB-430D-456B-887F-2A6ACD1F79D3</a:ObjectID>
<a:Name>Mettre à jour les places disponibles</a:Name>
<a:Code>mettreJourLesPlacesDisponibles</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o261">
<a:ObjectID>EF20FE50-1F16-4D56-A5E7-292F483E7CBF</a:ObjectID>
<a:Name>Empêcher une réservation lorsque le trajet est complet</a:Name>
<a:Code>empCherUneRServationLorsqueLeTrajetEstComplet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
</c:Operations>
<c:Identifiers>
<o:Identifier Id="o262">
<a:ObjectID>B271F2B5-BC63-4003-B269-D36B59CA44BF</a:ObjectID>
<a:Name>id_reservation</a:Name>
<a:Code>id_reservation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<c:Identifier.Attributes>
<o:Attribute Ref="o242"/>
</c:Identifier.Attributes>
</o:Identifier>
</c:Identifiers>
<c:PrimaryIdentifier>
<o:Identifier Ref="o262"/>
</c:PrimaryIdentifier>
</o:Class>
<o:Class Id="o78">
<a:ObjectID>319D9038-B453-4182-8D44-4E4A45562EEF</a:ObjectID>
<a:Name>PAIEMENT</a:Name>
<a:Code>paiement</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792189656</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:UseParentNamespace>0</a:UseParentNamespace>
<c:Attributes>
<o:Attribute Id="o263">
<a:ObjectID>9D24836B-A390-4C65-B2F2-1AF78658E268</a:ObjectID>
<a:Name>id_paiement</a:Name>
<a:Code>idPaiement</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o264">
<a:ObjectID>C142FA73-65F4-48C4-BA14-AB74052C7E83</a:ObjectID>
<a:Name>id_reservation</a:Name>
<a:Code>idReservation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o265">
<a:ObjectID>39B07073-28B3-448C-BBBC-4D1D884E6B4D</a:ObjectID>
<a:Name>montant</a:Name>
<a:Code>montant</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>float</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o266">
<a:ObjectID>BAE87F4B-ED2D-45CE-A4A5-A1F9479AFA64</a:ObjectID>
<a:Name>moyen_paiement</a:Name>
<a:Code>moyenPaiement</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o267">
<a:ObjectID>CBAAF539-1D6B-4A89-92E3-C013E56B2E94</a:ObjectID>
<a:Name>fournisseur</a:Name>
<a:Code>fournisseur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o268">
<a:ObjectID>BAE7C4F8-5515-45EC-AE72-13CBE681094E</a:ObjectID>
<a:Name>reference_transaction</a:Name>
<a:Code>referenceTransaction</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o269">
<a:ObjectID>B1BCAA97-D6DC-4DBE-8391-461F00034638</a:ObjectID>
<a:Name>statut</a:Name>
<a:Code>statut</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o270">
<a:ObjectID>2F24E8DA-0295-4395-A168-316F86492856</a:ObjectID>
<a:Name>date_paiement</a:Name>
<a:Code>datePaiement</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
</c:Attributes>
<c:Operations>
<o:Operation Id="o271">
<a:ObjectID>8F6134F7-9CF8-4013-84A7-06F7B53095C7</a:ObjectID>
<a:Name>Choisir le mode de paiement</a:Name>
<a:Code>choisirLeModeDePaiement</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o272">
<a:ObjectID>D5F77A21-2A8D-490B-A564-D541AFA4BB37</a:ObjectID>
<a:Name>Paiement en ligne</a:Name>
<a:Code>paiementEnLigne</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o273">
<a:ObjectID>134C04D8-E8CB-44CD-86E6-16B7C89CD5DF</a:ObjectID>
<a:Name>Enregistrer la transaction</a:Name>
<a:Code>enregistrerLaTransaction</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o274">
<a:ObjectID>478AD2D4-6159-4C1C-BA5E-D3F69274EB48</a:ObjectID>
<a:Name>Vérifier le paiement</a:Name>
<a:Code>vRifierLePaiement</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o275">
<a:ObjectID>F28414B9-EEE2-4C69-9C48-55B042A618E4</a:ObjectID>
<a:Name>Afficher le statut du paiement</a:Name>
<a:Code>afficherLeStatutDuPaiement</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o276">
<a:ObjectID>5A2F592F-4405-4B7B-BE21-CD4E477519C9</a:ObjectID>
<a:Name>Gérer un paiement échoué</a:Name>
<a:Code>gRerUnPaiementChou</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o277">
<a:ObjectID>8F0466E0-70EF-4575-9B32-26CD95682DBE</a:ObjectID>
<a:Name>Consulter l&amp;#x27historique des paiements</a:Name>
<a:Code>consulterLHistoriqueDesPaiements</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o278">
<a:ObjectID>E9F2754E-A39C-464E-919A-FE927C3AF8EC</a:ObjectID>
<a:Name>Générer une référence de transaction</a:Name>
<a:Code>gNRerUneRFRenceDeTransaction</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
</c:Operations>
<c:Identifiers>
<o:Identifier Id="o279">
<a:ObjectID>0BC49F8E-13CC-40C1-A81F-B65D45C26AF7</a:ObjectID>
<a:Name>id_paiement</a:Name>
<a:Code>id_paiement</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<c:Identifier.Attributes>
<o:Attribute Ref="o263"/>
</c:Identifier.Attributes>
</o:Identifier>
</c:Identifiers>
<c:PrimaryIdentifier>
<o:Identifier Ref="o279"/>
</c:PrimaryIdentifier>
</o:Class>
<o:Class Id="o79">
<a:ObjectID>41B525A4-6475-4454-991F-50EDD5F3839D</a:ObjectID>
<a:Name>CONVERSATION</a:Name>
<a:Code>conversation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792190189</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:UseParentNamespace>0</a:UseParentNamespace>
<c:Attributes>
<o:Attribute Id="o280">
<a:ObjectID>05DF5AF0-2F46-45E9-B306-8818D56F5050</a:ObjectID>
<a:Name>id_conversation</a:Name>
<a:Code>idConversation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o281">
<a:ObjectID>4BC24821-2577-4BCD-933A-6315B858BF5B</a:ObjectID>
<a:Name>id_reservation</a:Name>
<a:Code>idReservation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o282">
<a:ObjectID>F00B9FBC-7C06-4893-AF63-B922C4433FDC</a:ObjectID>
<a:Name>date_creation</a:Name>
<a:Code>dateCreation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o283">
<a:ObjectID>3D725429-7283-42F6-B6D3-A7CF143550E4</a:ObjectID>
<a:Name>statut</a:Name>
<a:Code>statut</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
</c:Attributes>
<c:Operations>
<o:Operation Id="o284">
<a:ObjectID>6EDEF987-077D-438F-8467-B3599630ED5A</a:ObjectID>
<a:Name>Créer une conversation</a:Name>
<a:Code>crErUneConversation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o285">
<a:ObjectID>8E27B4F3-657F-4679-8F05-8E35BB7DD93F</a:ObjectID>
<a:Name>Consulter l&amp;#x27historique</a:Name>
<a:Code>consulterLHistorique</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o286">
<a:ObjectID>0641C8BC-6153-4337-B758-97545A8C03D3</a:ObjectID>
<a:Name>Marquer comme lu</a:Name>
<a:Code>marquerCommeLu</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o287">
<a:ObjectID>D2F09463-7642-47AA-A6C8-C6CB18449C3F</a:ObjectID>
<a:Name>Vérifier l&amp;#x27accès à la conversation</a:Name>
<a:Code>vRifierLAccSLaConversation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
</c:Operations>
<c:Identifiers>
<o:Identifier Id="o288">
<a:ObjectID>C14F8AEF-A966-437D-B118-A99BC1BB8B90</a:ObjectID>
<a:Name>id_conversation</a:Name>
<a:Code>id_conversation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<c:Identifier.Attributes>
<o:Attribute Ref="o280"/>
</c:Identifier.Attributes>
</o:Identifier>
</c:Identifiers>
<c:PrimaryIdentifier>
<o:Identifier Ref="o288"/>
</c:PrimaryIdentifier>
</o:Class>
<o:Class Id="o80">
<a:ObjectID>5EA13081-A594-4DF9-864F-807F18A3549A</a:ObjectID>
<a:Name>MESSAGE</a:Name>
<a:Code>message</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792190189</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:UseParentNamespace>0</a:UseParentNamespace>
<c:Attributes>
<o:Attribute Id="o289">
<a:ObjectID>F13F08F6-5E4C-494A-93BD-08D63D2C6DB6</a:ObjectID>
<a:Name>id_message</a:Name>
<a:Code>idMessage</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o290">
<a:ObjectID>185F2920-4CCA-4BAA-9253-C645A52F1708</a:ObjectID>
<a:Name>id_conversation</a:Name>
<a:Code>idConversation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o291">
<a:ObjectID>46099156-1FBC-48E3-B1A5-C4DA75267D68</a:ObjectID>
<a:Name>id_expediteur</a:Name>
<a:Code>idExpediteur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o292">
<a:ObjectID>B691D0CE-46FB-4C18-A56D-C91757202184</a:ObjectID>
<a:Name>contenu</a:Name>
<a:Code>contenu</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o293">
<a:ObjectID>B7612341-D63E-4042-8179-6E0C2A3C97E7</a:ObjectID>
<a:Name>date_envoi</a:Name>
<a:Code>dateEnvoi</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o294">
<a:ObjectID>959987B3-5FE0-4A43-BD64-DC9E5B13FC2D</a:ObjectID>
<a:Name>lu</a:Name>
<a:Code>lu</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>boolean</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
</c:Attributes>
<c:Operations>
<o:Operation Id="o295">
<a:ObjectID>032AE0A9-1EEA-46A4-A9E4-401718ACD9CB</a:ObjectID>
<a:Name>Envoyer un message</a:Name>
<a:Code>envoyerUnMessage</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o296">
<a:ObjectID>B97EBF55-6217-48D4-A0E1-EFE10F4FC404</a:ObjectID>
<a:Name>Recevoir un message</a:Name>
<a:Code>recevoirUnMessage</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o297">
<a:ObjectID>69389BF9-9F32-4DBD-989A-9FF70FE7CF5F</a:ObjectID>
<a:Name>Marquer le message comme lu</a:Name>
<a:Code>marquerLeMessageCommeLu</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
</c:Operations>
<c:Identifiers>
<o:Identifier Id="o298">
<a:ObjectID>3DD92193-F787-484F-8975-F97B30643DC8</a:ObjectID>
<a:Name>id_message</a:Name>
<a:Code>id_message</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<c:Identifier.Attributes>
<o:Attribute Ref="o289"/>
</c:Identifier.Attributes>
</o:Identifier>
</c:Identifiers>
<c:PrimaryIdentifier>
<o:Identifier Ref="o298"/>
</c:PrimaryIdentifier>
</o:Class>
<o:Class Id="o81">
<a:ObjectID>6F7C245F-A848-4AD4-9D2D-2CC0572F473D</a:ObjectID>
<a:Name>NOTIFICATION</a:Name>
<a:Code>notification</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792190290</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:UseParentNamespace>0</a:UseParentNamespace>
<c:Attributes>
<o:Attribute Id="o299">
<a:ObjectID>DF705BB7-95BC-49D7-A811-09FA654247A6</a:ObjectID>
<a:Name>id_notification</a:Name>
<a:Code>idNotification</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o300">
<a:ObjectID>3E7BE451-C393-4078-BE03-ABE3C0E03E9D</a:ObjectID>
<a:Name>id_utilisateur</a:Name>
<a:Code>idUtilisateur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o301">
<a:ObjectID>1E7F5852-5D64-42DB-ABE5-8182B3A1F9C9</a:ObjectID>
<a:Name>type_notification</a:Name>
<a:Code>typeNotification</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o302">
<a:ObjectID>8F907440-7E49-467C-AAF8-36C65017688D</a:ObjectID>
<a:Name>titre</a:Name>
<a:Code>titre</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o303">
<a:ObjectID>CF4F21F1-F287-4725-882C-65CECC80BA76</a:ObjectID>
<a:Name>contenu</a:Name>
<a:Code>contenu</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o304">
<a:ObjectID>CF7A9B3A-48DD-4DA4-977E-C27123B2F91C</a:ObjectID>
<a:Name>canal</a:Name>
<a:Code>canal</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o305">
<a:ObjectID>81E113A4-B543-4C96-85A3-F5D6EDF168EE</a:ObjectID>
<a:Name>lu</a:Name>
<a:Code>lu</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>boolean</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o306">
<a:ObjectID>2331EB20-DC74-4E7D-B8B3-F26730000EA6</a:ObjectID>
<a:Name>date_envoi</a:Name>
<a:Code>dateEnvoi</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
</c:Attributes>
<c:Operations>
<o:Operation Id="o307">
<a:ObjectID>D9A4A983-8CBB-49E6-884D-D291DF1701C8</a:ObjectID>
<a:Name>Envoyer une notification</a:Name>
<a:Code>envoyerUneNotification</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o308">
<a:ObjectID>CF9F5E05-B485-4920-B32D-98202BAAADA0</a:ObjectID>
<a:Name>Envoyer une notification push</a:Name>
<a:Code>envoyerUneNotificationPush</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o309">
<a:ObjectID>A7A32CA3-6B81-46E7-AD4E-CDF955E9BE04</a:ObjectID>
<a:Name>Envoyer une notification SMS</a:Name>
<a:Code>envoyerUneNotificationSMS</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o310">
<a:ObjectID>580CD439-1565-4FD0-9F40-482F369B1C73</a:ObjectID>
<a:Name>Envoyer une notification email</a:Name>
<a:Code>envoyerUneNotificationEmail</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o311">
<a:ObjectID>4BD586DE-211F-465D-BB5D-5A7B97A94343</a:ObjectID>
<a:Name>Marquer la notification comme lue</a:Name>
<a:Code>marquerLaNotificationCommeLue</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
</c:Operations>
<c:Identifiers>
<o:Identifier Id="o312">
<a:ObjectID>101D5A23-A639-434D-BE0E-41B76251C1BD</a:ObjectID>
<a:Name>id_notification</a:Name>
<a:Code>id_notification</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<c:Identifier.Attributes>
<o:Attribute Ref="o299"/>
</c:Identifier.Attributes>
</o:Identifier>
</c:Identifiers>
<c:PrimaryIdentifier>
<o:Identifier Ref="o312"/>
</c:PrimaryIdentifier>
</o:Class>
<o:Class Id="o82">
<a:ObjectID>E4C95A06-61A7-4388-B47A-A55DB80138F8</a:ObjectID>
<a:Name>EVALUATION</a:Name>
<a:Code>evaluation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792194813</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:UseParentNamespace>0</a:UseParentNamespace>
<c:Attributes>
<o:Attribute Id="o313">
<a:ObjectID>19447E70-DA4C-4D50-9364-709D51718050</a:ObjectID>
<a:Name>id_evaluation</a:Name>
<a:Code>idEvaluation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o314">
<a:ObjectID>C4103C6D-F5C7-4899-A957-33D4EE536CA5</a:ObjectID>
<a:Name>id_trajet</a:Name>
<a:Code>idTrajet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o315">
<a:ObjectID>68CEBCA2-F689-4427-9456-444C654CFB0B</a:ObjectID>
<a:Name>id_auteur</a:Name>
<a:Code>idAuteur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o316">
<a:ObjectID>5DAEB4CA-F076-4A17-9917-4904B8B9D7C4</a:ObjectID>
<a:Name>id_evalue</a:Name>
<a:Code>idEvalue</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o317">
<a:ObjectID>8F884DB7-41F6-4932-8685-22C822F39941</a:ObjectID>
<a:Name>note</a:Name>
<a:Code>note</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o318">
<a:ObjectID>4116C499-C3F7-4FCD-BC9F-C5F1A4055B55</a:ObjectID>
<a:Name>commentaire</a:Name>
<a:Code>commentaire</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o319">
<a:ObjectID>EFC00A52-039B-496D-8D90-FBB2A22E0FDD</a:ObjectID>
<a:Name>date_evaluation</a:Name>
<a:Code>dateEvaluation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
</c:Attributes>
<c:Operations>
<o:Operation Id="o320">
<a:ObjectID>F520975E-91E2-4E1A-8135-4E5D71AB47AF</a:ObjectID>
<a:Name>Noter le conducteur</a:Name>
<a:Code>noterLeConducteur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o321">
<a:ObjectID>6C2E43A2-FE1B-423E-811E-EC62FF0129ED</a:ObjectID>
<a:Name>Noter le passager</a:Name>
<a:Code>noterLePassager</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o322">
<a:ObjectID>2A253633-734C-4060-AD78-A9725F5FCB74</a:ObjectID>
<a:Name>Donner une note</a:Name>
<a:Code>donnerUneNote</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o323">
<a:ObjectID>11C39F0C-567E-4D55-8121-FC0BE2CA17B5</a:ObjectID>
<a:Name>Ajouter un commentaire</a:Name>
<a:Code>ajouterUnCommentaire</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o324">
<a:ObjectID>3F265FC6-E4E4-4685-8B11-67867A1A00D7</a:ObjectID>
<a:Name>Consulter les avis</a:Name>
<a:Code>consulterLesAvis</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o325">
<a:ObjectID>55CCDA70-012D-416A-807A-679C29F25138</a:ObjectID>
<a:Name>Calculer la moyenne</a:Name>
<a:Code>calculerLaMoyenne</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o326">
<a:ObjectID>8D0475A5-033B-414A-86F5-C9671F1350D6</a:ObjectID>
<a:Name>Vérifier la fin du trajet</a:Name>
<a:Code>vRifierLaFinDuTrajet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
</c:Operations>
<c:Identifiers>
<o:Identifier Id="o327">
<a:ObjectID>684183B4-2C0A-4F07-AD46-299EE507E993</a:ObjectID>
<a:Name>id_evaluation</a:Name>
<a:Code>id_evaluation</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<c:Identifier.Attributes>
<o:Attribute Ref="o313"/>
</c:Identifier.Attributes>
</o:Identifier>
</c:Identifiers>
<c:PrimaryIdentifier>
<o:Identifier Ref="o327"/>
</c:PrimaryIdentifier>
</o:Class>
<o:Class Id="o83">
<a:ObjectID>A0FC273E-989A-41DA-931F-1F0D641D52ED</a:ObjectID>
<a:Name>SIGNALEMENT</a:Name>
<a:Code>signalement</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792195729</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:UseParentNamespace>0</a:UseParentNamespace>
<c:Attributes>
<o:Attribute Id="o328">
<a:ObjectID>73052A11-2EF5-4320-81B6-8E4682953192</a:ObjectID>
<a:Name>id_signalement</a:Name>
<a:Code>idSignalement</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o329">
<a:ObjectID>13953F81-DB38-40CD-AC72-08E3214FBCE8</a:ObjectID>
<a:Name>id_signaleur</a:Name>
<a:Code>idSignaleur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o330">
<a:ObjectID>2CA0A26C-33C4-409E-BB1C-EB0F4C8E8AC9</a:ObjectID>
<a:Name>id_utilisateur_signale</a:Name>
<a:Code>idUtilisateurSignale</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o331">
<a:ObjectID>96E68F09-28F6-441A-ADC4-D3D9C88A8B4F</a:ObjectID>
<a:Name>id_trajet</a:Name>
<a:Code>idTrajet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o332">
<a:ObjectID>21AD37C7-1110-47D7-8512-1A639E0BCAF5</a:ObjectID>
<a:Name>id_administrateur</a:Name>
<a:Code>idAdministrateur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o333">
<a:ObjectID>DD5F471D-F7D7-44CD-BF5E-DFBA82B4527D</a:ObjectID>
<a:Name>motif</a:Name>
<a:Code>motif</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o334">
<a:ObjectID>1EF272F2-F621-4B17-9F60-A4F0B634EA88</a:ObjectID>
<a:Name>description</a:Name>
<a:Code>description</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o335">
<a:ObjectID>32C84D61-EB5D-4D27-9AEF-CE8D3307E8ED</a:ObjectID>
<a:Name>statut</a:Name>
<a:Code>statut</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o336">
<a:ObjectID>10C329DF-8B15-4108-93FE-405026830456</a:ObjectID>
<a:Name>date_signalement</a:Name>
<a:Code>dateSignalement</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o337">
<a:ObjectID>30984D4A-A369-467F-A6C0-09D8A96C1CC3</a:ObjectID>
<a:Name>date_traitement</a:Name>
<a:Code>dateTraitement</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
</c:Attributes>
<c:Operations>
<o:Operation Id="o338">
<a:ObjectID>F1CFE4E2-B2F6-4E4E-A2A8-91F20C97723C</a:ObjectID>
<a:Name>Signaler un utilisateur</a:Name>
<a:Code>signalerUnUtilisateur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o339">
<a:ObjectID>700EA1D1-13C6-4E32-8880-13BCD1304C11</a:ObjectID>
<a:Name>Signaler un trajet</a:Name>
<a:Code>signalerUnTrajet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o340">
<a:ObjectID>2ED6491C-5AC5-437D-A0AF-C04F107C34D1</a:ObjectID>
<a:Name>Signaler un problème</a:Name>
<a:Code>signalerUnProblMe</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o341">
<a:ObjectID>176A82B6-1195-42A9-BCDC-554C2009DC4B</a:ObjectID>
<a:Name>Traiter un signalement</a:Name>
<a:Code>traiterUnSignalement</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
</c:Operations>
<c:Identifiers>
<o:Identifier Id="o342">
<a:ObjectID>0233AAD1-00F2-47C2-ACA7-180B97FD2E84</a:ObjectID>
<a:Name>id_signalement</a:Name>
<a:Code>id_signalement</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<c:Identifier.Attributes>
<o:Attribute Ref="o328"/>
</c:Identifier.Attributes>
</o:Identifier>
</c:Identifiers>
<c:PrimaryIdentifier>
<o:Identifier Ref="o342"/>
</c:PrimaryIdentifier>
</o:Class>
<o:Class Id="o84">
<a:ObjectID>0260CED4-77D5-48DB-8E7E-669002A1C106</a:ObjectID>
<a:Name>ALERTE_SOS</a:Name>
<a:Code>alerteSOS</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196223</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:UseParentNamespace>0</a:UseParentNamespace>
<c:Attributes>
<o:Attribute Id="o343">
<a:ObjectID>9279DE52-EED2-4306-8541-3073C5AC268F</a:ObjectID>
<a:Name>id_alerte_sos</a:Name>
<a:Code>idAlerteSos</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o344">
<a:ObjectID>179DAC53-5399-48F0-8776-0EF6DA6EA459</a:ObjectID>
<a:Name>id_utilisateur</a:Name>
<a:Code>idUtilisateur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o345">
<a:ObjectID>F96AD40F-3BE7-4321-8FBF-78F122F13BD0</a:ObjectID>
<a:Name>id_trajet</a:Name>
<a:Code>idTrajet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o346">
<a:ObjectID>16EAF722-7DBD-4979-8AE2-4CF563CA7591</a:ObjectID>
<a:Name>position</a:Name>
<a:Code>position</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o347">
<a:ObjectID>E65F4AEC-2E17-4246-B9A8-4EB0082D50C6</a:ObjectID>
<a:Name>date_declenchement</a:Name>
<a:Code>dateDeclenchement</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o348">
<a:ObjectID>E1ADC75C-60AD-43B1-9899-EA9B80175783</a:ObjectID>
<a:Name>statut</a:Name>
<a:Code>statut</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
</c:Attributes>
<c:Operations>
<o:Operation Id="o349">
<a:ObjectID>8DE5E435-0812-41B3-ACDE-966155861477</a:ObjectID>
<a:Name>Déclencher une alerte SOS</a:Name>
<a:Code>dClencherUneAlerteSOS</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o350">
<a:ObjectID>397E954B-B1C1-462D-92CD-E48D814FA6FA</a:ObjectID>
<a:Name>Enregistrer la position</a:Name>
<a:Code>enregistrerLaPosition</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o351">
<a:ObjectID>A92E3D51-3F27-4791-B6E9-4BC1BC88A017</a:ObjectID>
<a:Name>Gérer les alertes de sécurité</a:Name>
<a:Code>gRerLesAlertesDeSCurit</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
</c:Operations>
<c:Identifiers>
<o:Identifier Id="o352">
<a:ObjectID>9785AD25-5791-40D0-AFC4-B1793F11896D</a:ObjectID>
<a:Name>id_alerte_sos</a:Name>
<a:Code>id_alerte_sos</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<c:Identifier.Attributes>
<o:Attribute Ref="o343"/>
</c:Identifier.Attributes>
</o:Identifier>
</c:Identifiers>
<c:PrimaryIdentifier>
<o:Identifier Ref="o352"/>
</c:PrimaryIdentifier>
</o:Class>
<o:Class Id="o85">
<a:ObjectID>9CEB7EA7-23DE-4277-BA9E-F945D0BEF279</a:ObjectID>
<a:Name>PARTAGE_POSITION</a:Name>
<a:Code>partagePOSITION</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196363</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:UseParentNamespace>0</a:UseParentNamespace>
<c:Attributes>
<o:Attribute Id="o353">
<a:ObjectID>3BC3B2CF-77A7-4120-8AAE-998B1F7BA006</a:ObjectID>
<a:Name>id_partage_position</a:Name>
<a:Code>idPartagePosition</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o354">
<a:ObjectID>9ADC7DAE-B0DA-4C38-ADA8-DF6AE7016FCD</a:ObjectID>
<a:Name>id_utilisateur</a:Name>
<a:Code>idUtilisateur</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o355">
<a:ObjectID>00EFBAC4-8090-4413-BDD0-F3BDD621FCFE</a:ObjectID>
<a:Name>id_trajet</a:Name>
<a:Code>idTrajet</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o356">
<a:ObjectID>F5CCB9F0-6BB5-4278-8A26-2B998350715D</a:ObjectID>
<a:Name>position</a:Name>
<a:Code>position</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o357">
<a:ObjectID>C5B9E21E-0C6E-4783-AF1C-B707A00E9CBE</a:ObjectID>
<a:Name>date_position</a:Name>
<a:Code>datePosition</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o358">
<a:ObjectID>0B07CAD8-98C4-4DC8-8A3B-8747266E7FF1</a:ObjectID>
<a:Name>partage_actif</a:Name>
<a:Code>partageActif</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>boolean</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
</c:Attributes>
<c:Operations>
<o:Operation Id="o359">
<a:ObjectID>6DFC32A6-AFF0-4901-BA81-CF77FB2692E5</a:ObjectID>
<a:Name>Partager la position en temps réel</a:Name>
<a:Code>partagerLaPositionEnTempsREl</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o360">
<a:ObjectID>1216D967-8F39-479D-9BE8-4F8BC9A84016</a:ObjectID>
<a:Name>Partager la position avec des proches</a:Name>
<a:Code>partagerLaPositionAvecDesProches</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o361">
<a:ObjectID>2628197F-65E4-46A0-840F-EC756912AAF0</a:ObjectID>
<a:Name>Activer le partage</a:Name>
<a:Code>activerLePartage</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o362">
<a:ObjectID>A4B13045-8330-4077-A44D-C73736B2B031</a:ObjectID>
<a:Name>Désactiver le partage</a:Name>
<a:Code>dSactiverLePartage</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
</c:Operations>
<c:Identifiers>
<o:Identifier Id="o363">
<a:ObjectID>F9F96E90-1F5C-4E2F-B23E-D4182D98C440</a:ObjectID>
<a:Name>id_partage_position</a:Name>
<a:Code>id_partage_position</a:Code>
<a:CreationDate>1791671571</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791671571</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<c:Identifier.Attributes>
<o:Attribute Ref="o353"/>
</c:Identifier.Attributes>
</o:Identifier>
</c:Identifiers>
<c:PrimaryIdentifier>
<o:Identifier Ref="o363"/>
</c:PrimaryIdentifier>
</o:Class>
<o:Class Id="o86">
<a:ObjectID>4845FD2F-18B5-4ED7-8178-5F0C4A441F56</a:ObjectID>
<a:Name>CONFIRMATION_EMBARQUEMENT</a:Name>
<a:Code>ConfirmationEmbarquement</a:Code>
<a:CreationDate>1792078860</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792189434</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:UseParentNamespace>0</a:UseParentNamespace>
<c:Attributes>
<o:Attribute Id="o364">
<a:ObjectID>AF731C6D-05EC-4672-A90D-D94629ECF383</a:ObjectID>
<a:Name>id_confirmation</a:Name>
<a:Code>idConfirmation</a:Code>
<a:CreationDate>1792078863</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792079215</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o365">
<a:ObjectID>09572582-B24A-4AD3-A7EF-EC28E45433BE</a:ObjectID>
<a:Name>id_reservation</a:Name>
<a:Code>idReservation</a:Code>
<a:CreationDate>1792078863</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792079198</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o366">
<a:ObjectID>FE8FBB44-C7F0-47EB-815C-1A22F7B32A09</a:ObjectID>
<a:Name>code_pin</a:Name>
<a:Code>codePin</a:Code>
<a:CreationDate>1792078863</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792079198</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o367">
<a:ObjectID>32A2D6C8-9172-4B59-9C68-E742C4BEA484</a:ObjectID>
<a:Name>qr_code</a:Name>
<a:Code>qrCode</a:Code>
<a:CreationDate>1792078863</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792079198</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o368">
<a:ObjectID>5387B400-D3F2-4428-A6C2-2CE9E6809679</a:ObjectID>
<a:Name>statut</a:Name>
<a:Code>statut</a:Code>
<a:CreationDate>1792078863</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792079198</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o369">
<a:ObjectID>16C6E525-A4A4-4BBF-BF2A-A4EC457B3AC4</a:ObjectID>
<a:Name>date_confirmation</a:Name>
<a:Code>dateConfirmation</a:Code>
<a:CreationDate>1792078863</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792079198</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o370">
<a:ObjectID>48CF9687-D2CE-43AB-BE82-C78A6C9FCBEA</a:ObjectID>
<a:Name>id_utilisateur_confirmateur</a:Name>
<a:Code>idUtilisateurConfirmateur</a:Code>
<a:CreationDate>1792078863</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792079198</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
</c:Attributes>
<c:Operations>
<o:Operation Id="o371">
<a:ObjectID>B0FA53A7-A7DB-4E18-A83F-7509B8B30449</a:ObjectID>
<a:Name>genererCodePIN</a:Name>
<a:Code>genererCodePIN</a:Code>
<a:CreationDate>1792079207</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792079341</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o372">
<a:ObjectID>598B1E13-FDFA-4D65-A79F-D6409E4BF481</a:ObjectID>
<a:Name>genererQRCode</a:Name>
<a:Code>genererQRCode</a:Code>
<a:CreationDate>1792079207</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792079341</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o373">
<a:ObjectID>EBAB1B1E-34D3-452D-BCF0-99672E121270</a:ObjectID>
<a:Name>verifierCodePIN</a:Name>
<a:Code>verifierCodePIN</a:Code>
<a:CreationDate>1792079207</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792079341</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o374">
<a:ObjectID>685D2271-CFD8-403A-97D4-7CDAFFD27D41</a:ObjectID>
<a:Name>verifierQRCode</a:Name>
<a:Code>verifierQRCode</a:Code>
<a:CreationDate>1792079207</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792079341</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o375">
<a:ObjectID>174E52AA-679D-4BE3-B28C-6BBD0A3204C5</a:ObjectID>
<a:Name>confirmerEmbarquement</a:Name>
<a:Code>confirmerEmbarquement</a:Code>
<a:CreationDate>1792079207</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792079341</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o376">
<a:ObjectID>AA4FE866-DA60-4DAF-8D9C-4D5A71D1558D</a:ObjectID>
<a:Name>annulerConfirmation</a:Name>
<a:Code>annulerConfirmation</a:Code>
<a:CreationDate>1792079207</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792079341</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
</c:Operations>
<c:Identifiers>
<o:Identifier Id="o377">
<a:ObjectID>859C2D23-AE26-4F01-9BB1-1354E258EA79</a:ObjectID>
<a:Name>id_confirmation</a:Name>
<a:Code>id_confirmation</a:Code>
<a:CreationDate>1792079207</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792079215</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<c:Identifier.Attributes>
<o:Attribute Ref="o364"/>
</c:Identifier.Attributes>
</o:Identifier>
</c:Identifiers>
<c:PrimaryIdentifier>
<o:Identifier Ref="o377"/>
</c:PrimaryIdentifier>
</o:Class>
<o:Class Id="o87">
<a:ObjectID>38A09C9E-7CC9-4704-A6DA-414524166263</a:ObjectID>
<a:Name>ALERTE_RECHERCHE</a:Name>
<a:Code>AlerteRecherche</a:Code>
<a:CreationDate>1792196541</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196971</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:UseParentNamespace>0</a:UseParentNamespace>
<c:Attributes>
<o:Attribute Id="o378">
<a:ObjectID>64818D30-91FB-49B6-995C-37BCBDCE3C34</a:ObjectID>
<a:Name>id_alerte</a:Name>
<a:Code>idAlerte</a:Code>
<a:CreationDate>1792196543</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196703</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o379">
<a:ObjectID>F5CB7C78-31CF-4D51-83C3-ADC638514C4C</a:ObjectID>
<a:Name>ville_depart</a:Name>
<a:Code>villeDepart</a:Code>
<a:CreationDate>1792196543</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196834</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o380">
<a:ObjectID>DDCD20C8-DCF8-4E57-8DBC-BDBAFE5BF7B8</a:ObjectID>
<a:Name>ville_arrivee</a:Name>
<a:Code>villeArrivee</a:Code>
<a:CreationDate>1792196543</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196834</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o381">
<a:ObjectID>78A06EBA-3BDB-49E9-AA98-D92EB0384891</a:ObjectID>
<a:Name>date_depart</a:Name>
<a:Code>dateDepart</a:Code>
<a:CreationDate>1792196543</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196834</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o382">
<a:ObjectID>F85A2247-90A8-43BC-B20B-8F4553B65A9B</a:ObjectID>
<a:Name>date_creation</a:Name>
<a:Code>dateCreation</a:Code>
<a:CreationDate>1792196543</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196834</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>Date</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o383">
<a:ObjectID>C08BF65E-F6FF-4D0D-A8A8-9C882E2915EC</a:ObjectID>
<a:Name>statut</a:Name>
<a:Code>statut</a:Code>
<a:CreationDate>1792196543</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196834</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>String</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
<o:Attribute Id="o384">
<a:ObjectID>A2FBAAE0-FA74-4C43-9BC2-49A3697FBD0B</a:ObjectID>
<a:Name>id_utilisateur</a:Name>
<a:Code>idUtilisateur</a:Code>
<a:CreationDate>1792196543</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196834</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:DataType>int</a:DataType>
<a:Attribute.Visibility>-</a:Attribute.Visibility>
</o:Attribute>
</c:Attributes>
<c:Operations>
<o:Operation Id="o385">
<a:ObjectID>7078A4DC-99E6-4743-AA81-D775A635ED98</a:ObjectID>
<a:Name>creerAlerteRecherche</a:Name>
<a:Code>creerAlerteRecherche</a:Code>
<a:CreationDate>1792196697</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196834</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o386">
<a:ObjectID>5EB6E62C-0E39-44C5-A44A-5E074C2697F7</a:ObjectID>
<a:Name>consulterAlerteRecherche</a:Name>
<a:Code>consulterAlerteRecherche</a:Code>
<a:CreationDate>1792196697</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196834</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o387">
<a:ObjectID>D4FF7AA3-A446-4B93-8BA0-CE67C1B13429</a:ObjectID>
<a:Name>modifierAlerteRecherche</a:Name>
<a:Code>modifierAlerteRecherche</a:Code>
<a:CreationDate>1792196697</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196834</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o388">
<a:ObjectID>4602B8AD-07EF-43F2-A739-DD52267FA210</a:ObjectID>
<a:Name>supprimerAlerteRecherche</a:Name>
<a:Code>supprimerAlerteRecherche</a:Code>
<a:CreationDate>1792196697</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196834</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o389">
<a:ObjectID>8F797672-2310-4A36-A039-663718C3E6BA</a:ObjectID>
<a:Name>activerAlerteRecherche</a:Name>
<a:Code>activerAlerteRecherche</a:Code>
<a:CreationDate>1792196697</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196834</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o390">
<a:ObjectID>ED19120D-55F2-457B-89E3-4413E7F6C0D0</a:ObjectID>
<a:Name>desactiverAlerteRecherche</a:Name>
<a:Code>desactiverAlerteRecherche</a:Code>
<a:CreationDate>1792196697</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196834</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o391">
<a:ObjectID>B61D57F5-2527-4CAD-9863-ABF63F2338C0</a:ObjectID>
<a:Name>rechercherTrajetCorrespondant</a:Name>
<a:Code>rechercherTrajetCorrespondant</a:Code>
<a:CreationDate>1792196697</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196834</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
<o:Operation Id="o392">
<a:ObjectID>206AF747-E9F8-4C0C-89CB-2597343D6DC8</a:ObjectID>
<a:Name>envoyerNotification</a:Name>
<a:Code>envoyerNotification</a:Code>
<a:CreationDate>1792196697</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196834</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:ReturnType>void</a:ReturnType>
<a:TemplateBody>%DefaultBody%</a:TemplateBody>
</o:Operation>
</c:Operations>
<c:Identifiers>
<o:Identifier Id="o393">
<a:ObjectID>0C8493E4-27C0-4F10-9223-6E8F65A14ADB</a:ObjectID>
<a:Name>creerAlerteRecherche</a:Name>
<a:Code>creerAlerteRecherche</a:Code>
<a:CreationDate>1792196670</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196677</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<c:Identifier.Attributes>
<o:Attribute Ref="o378"/>
</c:Identifier.Attributes>
</o:Identifier>
<o:Identifier Id="o394">
<a:ObjectID>8EBC2457-5DD0-4FFF-A204-FC80E1445FC2</a:ObjectID>
<a:Name>id_alerte</a:Name>
<a:Code>id_alerte</a:Code>
<a:CreationDate>1792196697</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196703</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<c:Identifier.Attributes>
<o:Attribute Ref="o378"/>
</c:Identifier.Attributes>
</o:Identifier>
</c:Identifiers>
</o:Class>
</c:Classes>
<c:Associations>
<o:Association Id="o9">
<a:ObjectID>F51E98A7-61B7-4997-ABEF-6B195958C4D9</a:ObjectID>
<a:Name>Utilisateur possède préférence</a:Name>
<a:Code>utilisateur_preference</a:Code>
<a:CreationDate>1791898306</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791898990</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..1</a:RoleAMultiplicity>
<a:RoleBMultiplicity>1..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,276={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,6=&lt;None&gt;
{78C31404-0EE5-4FD0-9038-EE396B305F05},roleBContainer,6=&lt;None&gt;

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o69"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o73"/>
</c:Object2>
</o:Association>
<o:Association Id="o12">
<a:ObjectID>269C4A80-20AA-4018-8AD6-CA331DF6030D</a:ObjectID>
<a:Name>Association_2</a:Name>
<a:Code>association2</a:Code>
<a:CreationDate>1791899051</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791899725</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..*</a:RoleAMultiplicity>
<a:RoleBMultiplicity>1..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,276={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,6=&lt;None&gt;
{78C31404-0EE5-4FD0-9038-EE396B305F05},roleBContainer,6=&lt;None&gt;

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o70"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o73"/>
</c:Object2>
</o:Association>
<o:Association Id="o15">
<a:ObjectID>FC111A3E-D1A4-4CB2-848F-80F76D6E1BB3</a:ObjectID>
<a:Name>Utilisateur soumet document</a:Name>
<a:Code>utilisateur_document</a:Code>
<a:CreationDate>1791904651</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791906389</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..*</a:RoleAMultiplicity>
<a:RoleBMultiplicity>1..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,224={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,17=java.util.HashSet

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o72"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o73"/>
</c:Object2>
</o:Association>
<o:Association Id="o18">
<a:ObjectID>A898F8A8-7712-49AB-A881-036802AA71AC</a:ObjectID>
<a:Name>Utilisateur publie trajet</a:Name>
<a:Code>utilisateur_trajet</a:Code>
<a:CreationDate>1791907382</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791907420</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..*</a:RoleAMultiplicity>
<a:RoleBMultiplicity>1..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,224={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,17=java.util.HashSet

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o71"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o73"/>
</c:Object2>
</o:Association>
<o:Association Id="o21">
<a:ObjectID>832BFCA1-FB2D-427B-A2F4-F150A842C8A8</a:ObjectID>
<a:Name>Association_5</a:Name>
<a:Code>association5</a:Code>
<a:CreationDate>1791907482</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791908284</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..*</a:RoleAMultiplicity>
<a:RoleBMultiplicity>1..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,276={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,6=&lt;None&gt;
{78C31404-0EE5-4FD0-9038-EE396B305F05},roleBContainer,6=&lt;None&gt;

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o71"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o74"/>
</c:Object2>
</o:Association>
<o:Association Id="o24">
<a:ObjectID>6D26E446-4467-41E4-8B81-D6E20CC66F8E</a:ObjectID>
<a:Name>Trajet possède tarification courante</a:Name>
<a:Code>trajet_tarification</a:Code>
<a:CreationDate>1791909416</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791909478</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..1</a:RoleAMultiplicity>
<a:RoleBMultiplicity>1..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,276={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,6=&lt;None&gt;
{78C31404-0EE5-4FD0-9038-EE396B305F05},roleBContainer,6=&lt;None&gt;

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o71"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o75"/>
</c:Object2>
</o:Association>
<o:Association Id="o27">
<a:ObjectID>7F55420B-3A46-4F24-9C76-E8E62D8CE86D</a:ObjectID>
<a:Name>Association_7</a:Name>
<a:Code>association7</a:Code>
<a:CreationDate>1791910632</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791910716</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..*</a:RoleAMultiplicity>
<a:RoleBMultiplicity>1..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,276={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,6=&lt;None&gt;
{78C31404-0EE5-4FD0-9038-EE396B305F05},roleBContainer,6=&lt;None&gt;

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o73"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o77"/>
</c:Object2>
</o:Association>
<o:Association Id="o29">
<a:ObjectID>8589894D-A42C-466B-B1E6-F0B4ACAD7A68</a:ObjectID>
<a:Name>Association_8</a:Name>
<a:Code>association8</a:Code>
<a:CreationDate>1791910635</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1791910761</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..*</a:RoleAMultiplicity>
<a:RoleBMultiplicity>1..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,276={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,6=&lt;None&gt;
{78C31404-0EE5-4FD0-9038-EE396B305F05},roleBContainer,6=&lt;None&gt;

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o71"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o77"/>
</c:Object2>
</o:Association>
<o:Association Id="o32">
<a:ObjectID>B0736A94-8BC4-4E3A-B769-12E1A9CCC1F8</a:ObjectID>
<a:Name>Association_9</a:Name>
<a:Code>association9</a:Code>
<a:CreationDate>1791911194</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792189656</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..*</a:RoleAMultiplicity>
<a:RoleBMultiplicity>1..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,276={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,6=&lt;None&gt;
{78C31404-0EE5-4FD0-9038-EE396B305F05},roleBContainer,6=&lt;None&gt;

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o77"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o78"/>
</c:Object2>
</o:Association>
<o:Association Id="o35">
<a:ObjectID>DB56E427-183C-428B-808E-2CCAE49BA618</a:ObjectID>
<a:Name>Réservation possède confirmation embarquement</a:Name>
<a:Code>reservation_confirmation_embarquement</a:Code>
<a:CreationDate>1792188759</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792189434</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..1</a:RoleAMultiplicity>
<a:RoleBMultiplicity>1..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,276={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,6=&lt;None&gt;
{78C31404-0EE5-4FD0-9038-EE396B305F05},roleBContainer,6=&lt;None&gt;

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o86"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o77"/>
</c:Object2>
</o:Association>
<o:Association Id="o38">
<a:ObjectID>C6B3D5C9-53E4-4721-B722-689A2419A434</a:ObjectID>
<a:Name>Association_11</a:Name>
<a:Code>association11</a:Code>
<a:CreationDate>1792189846</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792189968</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..1</a:RoleAMultiplicity>
<a:RoleBMultiplicity>1..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,276={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,6=&lt;None&gt;
{78C31404-0EE5-4FD0-9038-EE396B305F05},roleBContainer,6=&lt;None&gt;

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o77"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o79"/>
</c:Object2>
</o:Association>
<o:Association Id="o41">
<a:ObjectID>D86C3A43-7115-497B-988D-A8C7F12DF14C</a:ObjectID>
<a:Name>Association_12</a:Name>
<a:Code>association12</a:Code>
<a:CreationDate>1792190056</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792190189</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..*</a:RoleAMultiplicity>
<a:RoleBMultiplicity>1..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,276={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,6=&lt;None&gt;
{78C31404-0EE5-4FD0-9038-EE396B305F05},roleBContainer,6=&lt;None&gt;

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o79"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o80"/>
</c:Object2>
</o:Association>
<o:Association Id="o44">
<a:ObjectID>5061C41B-9EDE-454A-A407-D7223426A6BE</a:ObjectID>
<a:Name>Utilisateur reçoit notifications</a:Name>
<a:Code>utilisateur_notification</a:Code>
<a:CreationDate>1792190262</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792190290</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..*</a:RoleAMultiplicity>
<a:RoleBMultiplicity>1..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,224={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,17=java.util.HashSet

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o81"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o73"/>
</c:Object2>
</o:Association>
<o:Association Id="o47">
<a:ObjectID>FDAC198A-0769-477A-8BE6-87504F4FABFA</a:ObjectID>
<a:Name>Association_14</a:Name>
<a:Code>association14</a:Code>
<a:CreationDate>1792190375</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792194813</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..*</a:RoleAMultiplicity>
<a:RoleBMultiplicity>1..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,276={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,6=&lt;None&gt;
{78C31404-0EE5-4FD0-9038-EE396B305F05},roleBContainer,6=&lt;None&gt;

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o71"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o82"/>
</c:Object2>
</o:Association>
<o:Association Id="o50">
<a:ObjectID>FB2EA96C-2F9C-48C6-A18E-3F7AB0F8DF76</a:ObjectID>
<a:Name>Association_15</a:Name>
<a:Code>association15</a:Code>
<a:CreationDate>1792194884</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792194964</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..*</a:RoleAMultiplicity>
<a:RoleBMultiplicity>1..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,276={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,6=&lt;None&gt;
{78C31404-0EE5-4FD0-9038-EE396B305F05},roleBContainer,6=&lt;None&gt;

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o73"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o83"/>
</c:Object2>
</o:Association>
<o:Association Id="o52">
<a:ObjectID>408187DA-DA5B-4D17-B096-BEC530AC62D0</a:ObjectID>
<a:Name>Association_16</a:Name>
<a:Code>association16</a:Code>
<a:CreationDate>1792195704</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792195729</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..*</a:RoleAMultiplicity>
<a:RoleBMultiplicity>0..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,276={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,6=&lt;None&gt;
{78C31404-0EE5-4FD0-9038-EE396B305F05},roleBContainer,6=&lt;None&gt;

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o71"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o83"/>
</c:Object2>
</o:Association>
<o:Association Id="o55">
<a:ObjectID>E3EC269F-9BC6-47C1-A1D1-02309D4EB183</a:ObjectID>
<a:Name>Association_17</a:Name>
<a:Code>association17</a:Code>
<a:CreationDate>1792195976</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196053</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..*</a:RoleAMultiplicity>
<a:RoleBMultiplicity>1..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,276={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,6=&lt;None&gt;
{78C31404-0EE5-4FD0-9038-EE396B305F05},roleBContainer,6=&lt;None&gt;

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o73"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o84"/>
</c:Object2>
</o:Association>
<o:Association Id="o57">
<a:ObjectID>C6C2AFE8-3ED5-49EC-BB76-561CDD5D9BDC</a:ObjectID>
<a:Name>Trajet peut être lié à alerte SOS</a:Name>
<a:Code>trajet_alerte_sos</a:Code>
<a:CreationDate>1792196193</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196223</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..*</a:RoleAMultiplicity>
<a:RoleBMultiplicity>0..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,276={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,6=&lt;None&gt;
{78C31404-0EE5-4FD0-9038-EE396B305F05},roleBContainer,6=&lt;None&gt;

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o71"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o84"/>
</c:Object2>
</o:Association>
<o:Association Id="o60">
<a:ObjectID>CC82E188-AC5D-4ACF-8234-23E6B6EB78BF</a:ObjectID>
<a:Name>Association_19</a:Name>
<a:Code>association19</a:Code>
<a:CreationDate>1792196279</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196305</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..*</a:RoleAMultiplicity>
<a:RoleBMultiplicity>1..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,276={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,6=&lt;None&gt;
{78C31404-0EE5-4FD0-9038-EE396B305F05},roleBContainer,6=&lt;None&gt;

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o73"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o85"/>
</c:Object2>
</o:Association>
<o:Association Id="o62">
<a:ObjectID>AF720853-2048-480B-A847-47494A686303</a:ObjectID>
<a:Name>Partage position peut concerner trajet</a:Name>
<a:Code>trajet_partage_position</a:Code>
<a:CreationDate>1792196342</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196363</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..*</a:RoleAMultiplicity>
<a:RoleBMultiplicity>0..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,276={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,6=&lt;None&gt;
{78C31404-0EE5-4FD0-9038-EE396B305F05},roleBContainer,6=&lt;None&gt;

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o71"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o85"/>
</c:Object2>
</o:Association>
<o:Association Id="o65">
<a:ObjectID>A771826D-B20C-4FA4-B885-4C3A291CC61E</a:ObjectID>
<a:Name>Association_21</a:Name>
<a:Code>association21</a:Code>
<a:CreationDate>1792196916</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792196971</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..*</a:RoleAMultiplicity>
<a:RoleBMultiplicity>1..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,276={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,6=&lt;None&gt;
{78C31404-0EE5-4FD0-9038-EE396B305F05},roleBContainer,6=&lt;None&gt;

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o73"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o87"/>
</c:Object2>
</o:Association>
<o:Association Id="o68">
<a:ObjectID>E4A3B50A-4685-4F1F-9990-3C94A13AC314</a:ObjectID>
<a:Name>Administrateur configure les paramètres de tarification</a:Name>
<a:Code>administrateur_parametre_tarification</a:Code>
<a:CreationDate>1792197138</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1792197166</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:RoleAMultiplicity>0..*</a:RoleAMultiplicity>
<a:RoleBMultiplicity>1..1</a:RoleBMultiplicity>
<a:RoleBNavigability>0</a:RoleBNavigability>
<a:ExtendedAttributesText>{0DEDDB90-46E2-45A0-886E-411709DA0DC9},Java,224={72FA5C48-5524-4DF7-8187-ABB19AB5AF9E},roleAContainer,6=&lt;None&gt;
{F6FFC71C-C472-4261-A710-B0BCC0BF4D58},roleAImplementationClass,6=&lt;None&gt;
{C11C9F66-6453-43A2-8824-6654518CF65A},roleBImplementationClass,17=java.util.HashSet

</a:ExtendedAttributesText>
<c:Object1>
<o:Class Ref="o73"/>
</c:Object1>
<c:Object2>
<o:Class Ref="o76"/>
</c:Object2>
</o:Association>
</c:Associations>
<c:TargetModels>
<o:TargetModel Id="o395">
<a:ObjectID>7E87B509-7CED-4920-9FBF-11D3202B6C3C</a:ObjectID>
<a:Name>Java</a:Name>
<a:Code>Java</a:Code>
<a:CreationDate>1791417237</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1202823188</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:TargetModelURL>file:///%[XOL]%/java5-j2ee14.xol</a:TargetModelURL>
<a:TargetModelID>0DEDDB90-46E2-45A0-886E-411709DA0DC9</a:TargetModelID>
<a:TargetModelClassID>1811206C-1A4B-11D1-83D9-444553540000</a:TargetModelClassID>
<a:TargetModelLastModificationDate>1202823188</a:TargetModelLastModificationDate>
<c:SessionShortcuts>
<o:Shortcut Ref="o3"/>
</c:SessionShortcuts>
</o:TargetModel>
<o:TargetModel Id="o396">
<a:ObjectID>05F668BD-832D-4401-A337-8B357054C245</a:ObjectID>
<a:Name>WSDL for Java</a:Name>
<a:Code>WSDLJava</a:Code>
<a:CreationDate>1791417238</a:CreationDate>
<a:Creator>Abdoulaye Wade</a:Creator>
<a:ModificationDate>1096028631</a:ModificationDate>
<a:Modifier>Abdoulaye Wade</a:Modifier>
<a:TargetModelURL>file:///%[XEM]%/WSDLJ2EE.xem</a:TargetModelURL>
<a:TargetModelID>C8F5F7B2-CF9D-4E98-8301-959BB6E86C8A</a:TargetModelID>
<a:TargetModelClassID>186C8AC3-D3DC-11D3-881C-00508B03C75C</a:TargetModelClassID>
<a:TargetModelLastModificationDate>1096028631</a:TargetModelLastModificationDate>
<c:SessionShortcuts>
<o:Shortcut Ref="o4"/>
</c:SessionShortcuts>
</o:TargetModel>
</c:TargetModels>
</o:Model>
</c:Children>
</o:RootObject>

</Model>