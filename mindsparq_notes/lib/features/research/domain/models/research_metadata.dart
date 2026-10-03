enum CitationFormat {
  apa7('APA 7th'),
  mla9('MLA 9th'),
  harvard('Harvard'),
  chicago('Chicago 17th'),
  ieee('IEEE');

  final String label;
  const CitationFormat(this.label);
}

class ResearchMetadata {
  final String noteId;
  final bool isResearchMode;
  final String sourceTitle;
  final String authors;
  final String publicationYear;
  final String journalOrPublisher;
  final String volumeAndPages;
  final String doiOrUrl;
  final String publicationType;
  final String abstractText;

  const ResearchMetadata({
    required this.noteId,
    this.isResearchMode = false,
    this.sourceTitle = '',
    this.authors = '',
    this.publicationYear = '',
    this.journalOrPublisher = '',
    this.volumeAndPages = '',
    this.doiOrUrl = '',
    this.publicationType = 'Journal Article',
    this.abstractText = '',
  });

  bool get hasCitationData =>
      sourceTitle.isNotEmpty || authors.isNotEmpty || publicationYear.isNotEmpty;

  /// Helper to split authors by comma or semicolon
  List<String> get authorList {
    if (authors.trim().isEmpty) return [];
    return authors
        .split(RegExp(r'[,;]'))
        .map((a) => a.trim())
        .where((a) => a.isNotEmpty)
        .toList();
  }

  /// Generates in-text citation e.g. (Turing, 1950) or (Turing & Smith, 1950)
  String generateInTextCitation() {
    final list = authorList;
    final year = publicationYear.trim().isNotEmpty ? publicationYear.trim() : 'n.d.';

    if (list.isEmpty) {
      final shortTitle = sourceTitle.isNotEmpty
          ? (sourceTitle.length > 25 ? '${sourceTitle.substring(0, 25)}...' : sourceTitle)
          : 'Anon.';
      return '("$shortTitle", $year)';
    }

    if (list.length == 1) {
      final lastName = _extractLastName(list[0]);
      return '($lastName, $year)';
    } else if (list.length == 2) {
      final last1 = _extractLastName(list[0]);
      final last2 = _extractLastName(list[1]);
      return '($last1 & $last2, $year)';
    } else {
      final last1 = _extractLastName(list[0]);
      return '($last1 et al., $year)';
    }
  }

  /// APA 7th Edition
  String generateAPA7() {
    final list = authorList;
    final year = publicationYear.trim().isNotEmpty ? '(${publicationYear.trim()}).' : '(n.d.).';
    final title = sourceTitle.trim().isNotEmpty ? sourceTitle.trim() : 'Untitled Work';
    final journal = journalOrPublisher.trim();
    final vol = volumeAndPages.trim();
    final doi = doiOrUrl.trim();

    final buffer = StringBuffer();

    // Authors
    if (list.isEmpty) {
      buffer.write('$title. ');
    } else if (list.length == 1) {
      buffer.write('${_formatAuthorAPA(list[0])} ');
    } else {
      for (int i = 0; i < list.length; i++) {
        if (i == list.length - 1) {
          buffer.write('& ${_formatAuthorAPA(list[i])} ');
        } else {
          buffer.write('${_formatAuthorAPA(list[i])}, ');
        }
      }
    }

    // Year & Title
    buffer.write('$year ');
    if (list.isNotEmpty) {
      buffer.write('$title. ');
    }

    // Source
    if (journal.isNotEmpty) {
      buffer.write('*$journal*');
      if (vol.isNotEmpty) buffer.write(', $vol');
      buffer.write('. ');
    }

    // DOI / URL
    if (doi.isNotEmpty) {
      buffer.write(doi.startsWith('http') ? doi : 'https://doi.org/$doi');
    }

    return buffer.toString().trim();
  }

  /// MLA 9th Edition
  String generateMLA9() {
    final list = authorList;
    final year = publicationYear.trim();
    final title = sourceTitle.trim().isNotEmpty ? '"${sourceTitle.trim()}."' : '"Untitled."';
    final journal = journalOrPublisher.trim();
    final vol = volumeAndPages.trim();
    final doi = doiOrUrl.trim();

    final buffer = StringBuffer();

    if (list.isNotEmpty) {
      if (list.length == 1) {
        buffer.write('${list[0]}. ');
      } else if (list.length == 2) {
        buffer.write('${list[0]}, and ${list[1]}. ');
      } else {
        buffer.write('${list[0]}, et al. ');
      }
    }

    buffer.write('$title ');

    if (journal.isNotEmpty) {
      buffer.write('*$journal*, ');
    }
    if (vol.isNotEmpty) {
      buffer.write('$vol, ');
    }
    if (year.isNotEmpty) {
      buffer.write('$year. ');
    }
    if (doi.isNotEmpty) {
      buffer.write(doi);
    }

    return buffer.toString().trim();
  }

  /// Harvard Reference Style
  String generateHarvard() {
    final list = authorList;
    final year = publicationYear.trim().isNotEmpty ? publicationYear.trim() : 'n.d.';
    final title = sourceTitle.trim().isNotEmpty ? sourceTitle.trim() : 'Untitled';
    final journal = journalOrPublisher.trim();
    final vol = volumeAndPages.trim();

    final buffer = StringBuffer();

    if (list.isNotEmpty) {
      if (list.length == 1) {
        buffer.write('${_formatAuthorAPA(list[0])}, ');
      } else {
        buffer.write('${_formatAuthorAPA(list[0])} and ${_formatAuthorAPA(list[1])}, ');
      }
    }

    buffer.write('$year. $title. ');
    if (journal.isNotEmpty) {
      buffer.write('*$journal*');
      if (vol.isNotEmpty) buffer.write(', $vol');
      buffer.write('.');
    }

    return buffer.toString().trim();
  }

  /// IEEE Style
  String generateIEEE() {
    final list = authorList;
    final year = publicationYear.trim();
    final title = sourceTitle.trim().isNotEmpty ? '"${sourceTitle.trim()},"' : '"Untitled,"';
    final journal = journalOrPublisher.trim();
    final vol = volumeAndPages.trim();

    final buffer = StringBuffer();
    buffer.write('[1] ');

    if (list.isNotEmpty) {
      buffer.write('${list.join(", ")}, ');
    }

    buffer.write('$title ');

    if (journal.isNotEmpty) {
      buffer.write('*$journal*');
      if (vol.isNotEmpty) buffer.write(', $vol');
      if (year.isNotEmpty) buffer.write(', $year');
      buffer.write('.');
    } else if (year.isNotEmpty) {
      buffer.write('$year.');
    }

    return buffer.toString().trim();
  }

  /// Chicago 17th Notes & Bibliography
  String generateChicago17() {
    final list = authorList;
    final year = publicationYear.trim();
    final title = sourceTitle.trim().isNotEmpty ? '"${sourceTitle.trim()}."' : '"Untitled."';
    final journal = journalOrPublisher.trim();
    final vol = volumeAndPages.trim();

    final buffer = StringBuffer();

    if (list.isNotEmpty) {
      buffer.write('${list.join(", ")}. ');
    }

    buffer.write('$title ');

    if (journal.isNotEmpty) {
      buffer.write('*$journal*');
      if (vol.isNotEmpty) buffer.write(' $vol');
      if (year.isNotEmpty) buffer.write(' ($year)');
      buffer.write('.');
    } else if (year.isNotEmpty) {
      buffer.write('$year.');
    }

    return buffer.toString().trim();
  }

  String format(CitationFormat format) {
    switch (format) {
      case CitationFormat.apa7:
        return generateAPA7();
      case CitationFormat.mla9:
        return generateMLA9();
      case CitationFormat.harvard:
        return generateHarvard();
      case CitationFormat.chicago:
        return generateChicago17();
      case CitationFormat.ieee:
        return generateIEEE();
    }
  }

  static String _extractLastName(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.last : name;
  }

  static String _formatAuthorAPA(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length <= 1) return name;
    final last = parts.last;
    final initials = parts.sublist(0, parts.length - 1).map((p) => '${p[0]}.').join(' ');
    return '$last, $initials';
  }

  Map<String, dynamic> toJson() => {
        'noteId': noteId,
        'isResearchMode': isResearchMode,
        'sourceTitle': sourceTitle,
        'authors': authors,
        'publicationYear': publicationYear,
        'journalOrPublisher': journalOrPublisher,
        'volumeAndPages': volumeAndPages,
        'doiOrUrl': doiOrUrl,
        'publicationType': publicationType,
        'abstractText': abstractText,
      };

  factory ResearchMetadata.fromJson(Map<String, dynamic> json) {
    return ResearchMetadata(
      noteId: json['noteId'] as String? ?? '',
      isResearchMode: json['isResearchMode'] as bool? ?? false,
      sourceTitle: json['sourceTitle'] as String? ?? '',
      authors: json['authors'] as String? ?? '',
      publicationYear: json['publicationYear'] as String? ?? '',
      journalOrPublisher: json['journalOrPublisher'] as String? ?? '',
      volumeAndPages: json['volumeAndPages'] as String? ?? '',
      doiOrUrl: json['doiOrUrl'] as String? ?? '',
      publicationType: json['publicationType'] as String? ?? 'Journal Article',
      abstractText: json['abstractText'] as String? ?? '',
    );
  }

  ResearchMetadata copyWith({
    String? noteId,
    bool? isResearchMode,
    String? sourceTitle,
    String? authors,
    String? publicationYear,
    String? journalOrPublisher,
    String? volumeAndPages,
    String? doiOrUrl,
    String? publicationType,
    String? abstractText,
  }) {
    return ResearchMetadata(
      noteId: noteId ?? this.noteId,
      isResearchMode: isResearchMode ?? this.isResearchMode,
      sourceTitle: sourceTitle ?? this.sourceTitle,
      authors: authors ?? this.authors,
      publicationYear: publicationYear ?? this.publicationYear,
      journalOrPublisher: journalOrPublisher ?? this.journalOrPublisher,
      volumeAndPages: volumeAndPages ?? this.volumeAndPages,
      doiOrUrl: doiOrUrl ?? this.doiOrUrl,
      publicationType: publicationType ?? this.publicationType,
      abstractText: abstractText ?? this.abstractText,
    );
  }
}
