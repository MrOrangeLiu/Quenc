import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:quenc/models/Post.dart';
import 'package:quenc/models/User.dart';
import 'package:quenc/providers/PostService.dart';
import 'package:quenc/widgets/post/PostPreviewFullScreenDialog.dart';

// This one should be able for editing and addding
class PostAddingFullScreenDialog extends StatefulWidget {
  @override
  _PostAddingFullScreenDialogState createState() =>
      _PostAddingFullScreenDialogState();
}

class _PostAddingFullScreenDialogState
    extends State<PostAddingFullScreenDialog> {
  final _form = GlobalKey<FormState>();
  final RegExp imageReg = RegExp(r"!\[.*?\]\(.*?\)");

  final FirebaseStorage _storage =
      FirebaseStorage(storageBucket: "gs://quenc-hlc.appspot.com");

  StorageUploadTask _uploadTask;
  String currentUploadURL;
  String currentFilePath;

  TextEditingController contentController = TextEditingController();

  void _startUploadImage() {
    currentFilePath = "images/${DateTime.now()}.png";
    // _storage.ref().child(filePath).getDownloadURL().then((url) {
    //   setState(() {
    //     currentUploadURL = url as String;
    //   });
    // });

    setState(() {
      _uploadTask =
          _storage.ref().child(currentFilePath).putFile(currentInsertImage);
    });
  }

  File currentInsertImage;

  Post post = Post(
    anonymous: false,
    title: "",
    content: "",
    // comments: [],
    // archiveBy: [],
    // likeBy: [],
  );

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    contentController.text = post.content;
  }

  void _submit(BuildContext ctx) {
    if (!_form.currentState.validate()) {
      return;
    }

    _form.currentState.save();
    addPost(context);
  }

  String getDisplayNameFromEmail(String email) {
    List<String> emailParts = email.split("@");
    if (emailParts.length > 2) {
      return null;
    }

    String uni = "";

    switch (emailParts[1]) {
      case "qut.edu.au":
        uni = "Queensland University of Technology";
        break;
      case "uq.edu.au":
        uni = "University of Queensland";
        break;
      case "griffith.edu.au":
        uni = "Griffith University";
        break;
      default:
        uni = null;
    }

    return uni;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // if (currentInsertImage != null) {
    //   Scaffold.of(context).removeCurrentSnackBar();
    //   Scaffold.of(context).showSnackBar(SnackBar(
    //     content: Text("You have an image in ${currentInsertImage.path}"),
    //   ));
    // }
  }

  Future<void> _pickImage(ImageSource source) async {
    File selected = await ImagePicker.pickImage(source: source);

    setState(() {
      currentInsertImage = selected;
    });

    // Uploading the image here
  }

  String getFirstImageURLFromMarkdown(String content) {
    var match = imageReg.firstMatch(content);
    String firstImageUrl = post.content.substring(match.start, match.end);
    // print(firstImageUrl);
    int idxStart = firstImageUrl.indexOf("(");
    String retrievedURL =
        firstImageUrl.substring(idxStart + 1, firstImageUrl.length - 1);
    return retrievedURL;
  }

  Future<void> _cropImage() async {
    File cropped = await ImageCropper.cropImage(
      sourcePath: currentInsertImage.path,
      compressFormat: ImageCompressFormat.png,
      // ratioX: 1.0,
      // ratioY: 1.0,
      // maxWidth: 512,
      // maxHeight: 512,
    );

    setState(() {
      currentInsertImage = cropped ?? currentInsertImage;
    });
  }

  String getPreviewText(String content) {
    String preview = "";

    List<String> sentences = content.split("\n");

    for (String s in sentences) {
      if (!imageReg.hasMatch(s)) {
        return content;
      }
    }

    return preview;
  }

  void addPost(BuildContext ctx) async {
    // Initialise the fields
    var u = Provider.of<User>(ctx, listen: false);
    post.author = u.uid;
    post.authorGender = u.gender;
    post.authorName = getDisplayNameFromEmail(u.email);
    post.previewPhoto = getFirstImageURLFromMarkdown(post.content);
    post.createdAt = DateTime.now();
    post.updatedAt = DateTime.now();

    // Add to the post collection
    String postId =
        await Provider.of<PostService>(ctx, listen: false).addPost(post);

    // Add to the user collection
    // UserService().addPostToUser(postId, post.author);

    Navigator.of(ctx).pop();
  }

  bool prepairPostForPreview() {
    if (!_form.currentState.validate()) {
      return false;
    }

    _form.currentState.save();

    var u = Provider.of<User>(context, listen: false);
    post.author = u.uid;
    post.authorGender = u.gender;
    post.authorName = getDisplayNameFromEmail(u.email);
    post.previewPhoto = getFirstImageURLFromMarkdown(post.content);
    post.createdAt = DateTime.now();
    post.updatedAt = DateTime.now();

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // resizeToAvoidBottomPadding: false,
      // appBar: AppBar(
      //   title: Text("新增文章"),
      //   actions: <Widget>[
      //     Padding(
      //       padding: const EdgeInsets.all(8.0),
      //       child: RaisedButton(
      //         child: Text("發表"),
      //         onPressed: () {
      //           _submit(context);
      //         },
      //       ),
      //     ),
      //   ],
      // ),
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerBoxIsScrolled) {
          return <Widget>[
            SliverAppBar(
              title: Text("新增文章"),
              floating: true,
              // pinned: true,
              snap: true,
              // primary: true,
              // forceElevated: innerBoxIsScrolled,
              actions: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: RaisedButton(
                    child: Text("發表"),
                    onPressed: () {
                      _submit(context);
                    },
                  ),
                ),
              ],
              // bottom: TabBar(
              //   tabs: <Widget>[
              //     Tab(
              //       text: "編輯",
              //     ),
              //     Tab(
              //       text: "預覽",
              //     ),
              //   ],
              // ),
            ),
          ];
        },
        body: Form(
          key: _form,
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Container(
                child: Row(
                  children: <Widget>[
                    Flexible(
                      flex: 3,
                      fit: FlexFit.loose,
                      child: Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: TextFormField(
                          initialValue: post.title,
                          decoration: const InputDecoration(
                            // labelText: "標題",
                            border: InputBorder.none,
                            hintText: "標題",
                            // border: const OutlineInputBorder(),
                          ),
                          onSaved: (v) {
                            post.title = v;
                          },
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return "請輸入標題";
                            }
                            if (v.length > 20) {
                              return "標題不可多於20個字元";
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 1,
                      fit: FlexFit.loose,
                      child: CheckboxListTile(
                        secondary: Text("匿名"),
                        // title: Text("匿名"),
                        value: post.anonymous,
                        onChanged: (v) {
                          setState(() {
                            post.anonymous = v;
                          });
                        },
                      ),
                    )
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(15.0),
                child: TextFormField(
                  // initialValue: post.title,
                  // minLines: 5,
                  // maxLines: 13,
                  minLines: 40,
                  controller: contentController,
                  maxLines: null,
                  // scrollPadding: EdgeInsets.all(60),
                  // onChanged: (v) {
                  //   setState(() {});
                  // },
                  decoration: const InputDecoration(
                    // labelText: "內容",
                    hintText: "內容",
                    border: InputBorder.none,
                    // border: const OutlineInputBorder(),
                  ),
                  onSaved: (v) {
                    // Adding the Markdown parserr here
                    post.content = v;
                  },
                  validator: (v) {
                    if (v == null || v.isEmpty) {
                      return "請輸入內容";
                    }

                    if (v.length < 20) {
                      return "內容必須多餘20個字元";
                    }

                    return null;
                  },
                ),
              ),
              SizedBox(
                height: MediaQuery.of(context).size.height,
              )
            ],
          ),
        ),
      ),
      resizeToAvoidBottomInset: true,
      // bottomSheet: Transform.translate(
      //   offset: Offset(0.0, -1 * MediaQuery.of(context).viewInsets.bottom),
      //   child: BottomSheet(
      //     onClosing: () {},
      //     builder: (context) {
      //       return Container(
      //         height: 20,
      //         color: Colors.red,
      //       );
      //     },
      //   ),
      // ),
      bottomNavigationBar: Transform.translate(
        offset: Offset(0.0, -1 * MediaQuery.of(context).viewInsets.bottom),
        child: BottomAppBar(
          child: Wrap(
            children: <Widget>[
              if (currentInsertImage != null)
                Card(
                  // decoration: BoxDecoration(
                  //   border: Border.all(),
                  // ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Flexible(
                        flex: 1,
                        fit: FlexFit.loose,
                        child: Container(
                          padding: EdgeInsets.all(6),
                          child: Image.file(
                            currentInsertImage,
                            fit: BoxFit.scaleDown,
                          ),
                          height: 100,
                          width: 100,
                        ),
                      ),
                      if (_uploadTask == null)
                        Flexible(
                          flex: 1,
                          fit: FlexFit.loose,
                          child: IconButton(
                            icon: Icon(Icons.crop),
                            onPressed: () {
                              _cropImage();
                            },
                          ),
                        ),

                      Flexible(
                        flex: 2,
                        fit: FlexFit.loose,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: _uploadTask == null
                                ? IconButton(
                                    icon: Icon(Icons.cloud_upload),
                                    onPressed: () {
                                      _startUploadImage();
                                    },
                                  )
                                : StreamBuilder(
                                    stream: _uploadTask.events,
                                    builder: (context, snapshot) {
                                      dynamic d = snapshot?.data;
                                      var event = d?.snapshot;

                                      double progressPercent = event != null
                                          ? event.bytesTransferred /
                                              event.totalByteCount
                                          : 0;

                                      if (_uploadTask.isComplete) {
                                        _storage
                                            .ref()
                                            .child(currentFilePath)
                                            .getDownloadURL()
                                            .then((url) {
                                          String urlString = url as String;

                                          if (currentUploadURL == urlString) {
                                            return;
                                          }

                                          setState(() {
                                            currentUploadURL = url as String;
                                          });
                                        });
                                      }

                                      return _uploadTask.isComplete
                                          ? ListTile(
                                              title: Text("上傳成功"),
                                              trailing: FlatButton(
                                                child: Text(
                                                  "插入",
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                                onPressed: () {
                                                  String addingImageMd = "\n" +
                                                      "![圖片載入中...](" +
                                                      currentUploadURL +
                                                      ")" +
                                                      "\n";

                                                  var cursorPosition =
                                                      contentController
                                                          .selection;
                                                  var idx =
                                                      cursorPosition.start;

                                                  if (idx != -1) {
                                                    contentController
                                                        .text = contentController
                                                            .text
                                                            .substring(0, idx) +
                                                        addingImageMd +
                                                        contentController.text
                                                            .substring(
                                                                idx,
                                                                contentController
                                                                    .text
                                                                    .length);
                                                  } else {
                                                    contentController.text +=
                                                        addingImageMd;
                                                  }

                                                  if (cursorPosition.start >
                                                      contentController
                                                          .text.length) {
                                                    cursorPosition =
                                                        TextSelection
                                                            .fromPosition(
                                                      TextPosition(
                                                          offset:
                                                              contentController
                                                                  .text.length),
                                                    );

                                                    contentController
                                                            .selection =
                                                        cursorPosition;
                                                  } else {
                                                    contentController
                                                            .selection =
                                                        TextSelection.fromPosition(
                                                            TextPosition(
                                                                offset: cursorPosition
                                                                        .start +
                                                                    addingImageMd
                                                                        .length));
                                                  }

                                                  // contentController.selection =
                                                  //     TextSelection.collapsed(
                                                  //         offset: contentController.text.length );
                                                  setState(() {
                                                    _uploadTask = null;
                                                    currentFilePath = null;
                                                    currentUploadURL = null;
                                                    currentInsertImage = null;
                                                  });
                                                },
                                              ),
                                            )
                                          : Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                  // if (_uploadTask.isPaused)
                                                  //   FlatButton(
                                                  //     child: Icon(Icons.play_arrow, size: 50),
                                                  //     onPressed: _uploadTask.resume,
                                                  //   ),
                                                  // if (_uploadTask.isInProgress)
                                                  //   FlatButton(
                                                  //     child: Icon(Icons.pause, size: 50),
                                                  //     onPressed: _uploadTask.pause,
                                                  //   ),
                                                  Text(
                                                    '${(progressPercent * 100).toStringAsFixed(2)} % ',
                                                  ),
                                                  LinearProgressIndicator(
                                                      value: progressPercent),

                                                  Text(
                                                    '上傳中',
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      // height: 2,
                                                    ),
                                                  ),
                                                ]);
                                    },
                                  ),
                          ),
                        ),
                      ),

                      // if (_uploadTask != null && _uploadTask.isComplete)
                      //   FlatButton(
                      //     child: Text("插入"),
                      //     onPressed: () {},
                      //   )

                      // if (_uploadTask == null)
                      //   IconButton(
                      //     icon: Icon(Icons.cloud_upload),
                      //     onPressed: () {
                      //       _startUploadImage();
                      //     },
                      //   ),
                      // if (_uploadTask != null)
                      //   StreamBuilder(
                      //     stream: _uploadTask.events,
                      //     builder: (context, snapshot) {
                      //       dynamic d = snapshot?.data;
                      //       var event = d?.snapshot;

                      //       double progressPercent = event != null
                      //           ? event.bytesTransferred / event.totalByteCount
                      //           : 0;

                      //       return Column(
                      //           mainAxisAlignment: MainAxisAlignment.center,
                      //           crossAxisAlignment: CrossAxisAlignment.center,
                      //           children: [
                      //             if (_uploadTask.isComplete)
                      //               Text('可插入',
                      //                   style: TextStyle(
                      //                       color: Colors.greenAccent,
                      //                       height: 2,
                      //                       fontSize: 30)),
                      //             // if (_uploadTask.isPaused)
                      //             //   FlatButton(
                      //             //     child: Icon(Icons.play_arrow, size: 50),
                      //             //     onPressed: _uploadTask.resume,
                      //             //   ),
                      //             // if (_uploadTask.isInProgress)
                      //             //   FlatButton(
                      //             //     child: Icon(Icons.pause, size: 50),
                      //             //     onPressed: _uploadTask.pause,
                      //             //   ),
                      //             LinearProgressIndicator(value: progressPercent),
                      //             Text(
                      //               '${(progressPercent * 100).toStringAsFixed(2)} % ',
                      //               style: TextStyle(fontSize: 50),
                      //             ),
                      //           ]);
                      //     },
                      //   )
                    ],
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  FlatButton(
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.photo_camera),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("相機"),
                        ),
                      ],
                    ),
                    // icon: Icon(Icons.photo_camera),
                    onPressed: () {
                      _pickImage(ImageSource.camera);
                    },
                  ),
                  FlatButton(
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.image),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("相簿"),
                        ),
                      ],
                    ),
                    // icon: Icon(Icons.image),
                    onPressed: () {
                      _pickImage(ImageSource.gallery);
                    },
                  ),
                  FlatButton(
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.remove_red_eye),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("預覽"),
                        ),
                      ],
                    ),
                    // icon: ,
                    onPressed: () {
                      bool ok = prepairPostForPreview();
                      if (ok) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) {
                              final dialog = PostPreviewFullScreenDialog(
                                // inputText: contentController.text,
                                post: post,
                              );
                              return dialog;
                            },
                            fullscreenDialog: true,
                          ),
                        );
                      }
                    },
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
